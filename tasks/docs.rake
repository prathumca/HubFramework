require 'fileutils'
require 'rake'
require 'safe_yaml'
require 'securerandom'
require 'tmpdir'
require 'yaml'

#
# Rake task for generating API documentation.
#
# Also see the associated Jazzy configurations file.
#

# We want to safely parse our yaml :)
SafeYAML::OPTIONS[:default_mode] = :safe

config_default = '.jazzy.yml'

publish_git_repo_default = 'git@ghe.spotify.net:iOS/HubFramework.git'
publish_git_branch_default = 'gh-pages'

namespace :docs do

    #
    # Misc tasks

    desc "Generate and publish the documentation"
    task :all => [:generate, :publish]

    desc "Install dependencies"
    task :deps do
        puts "📖  👉   Installing dependencies…"
        system('bundle', 'install', '--quiet') or abort('bundle install failed, make sure you have installed bundler (`[sudo] gem install bundler`)')
        puts "📖  ✅   Dependencies installed successfully."
    end

    #
    # Generating documentation

    desc "Generate the documentation"
    task :generate, [:config] => [:deps] do |t, args|
        puts "📖  👉   Generating documentation…"

        args.with_defaults(:config => config_default)
        config_path = args[:config]

        execute_jazzy('--config', config_path) or abort("📖  ❗️  Failed to generate documentation, aborting.")

        config = YAML.load_file(config_path)
        copy_extra_resources(config)
        rebuild_docset_archive(config) # We need to rebuild the DocSet archive since we’ve copied more resources into it.

        puts "📖  ✅   Generated successfully."
    end

    #
    # Publishing the documentation

    desc "Publish the documentation to gh-pages"
    task :publish, [:repo, :branch] do |t, args|
        puts "📖  👉   Publishing documentation…"

        # TODO: Figure out how to get the jazzy config if someone provides :generate a custom one
        config = YAML.load_file(config_default) or abort("📖  ❗️  Failed to read jazzy config, aborting.")
        docs_path = config["output"] 

        if not File.directory?(docs_path)
            puts "📖  ❗️  No documentation found, aborting."
            exit!(1)
        end

        args.with_defaults(:repo => publish_git_repo_default)
        args.with_defaults(:branch => publish_git_branch_default)

        tmp_dir = publish_tmp_dir_path()
        repo_name = "docs-repo"
        repo_dir = File.join(tmp_dir, repo_name)

        prepare_publish_dir(tmp_dir)

        git_clone_repo(args[:repo], args[:branch], repo_dir)
        publish_docs(tmp_dir, repo_dir, args[:branch], docs_path, git_head_hash(repo_dir))
        #cleanup_publish_dir(repo_dir)

        puts "📖  ✅   Published successfully."
    end


    #
    # Helper functions

    # Run jazzy with the given arguments
    def execute_jazzy(*args)
        system('bundle', 'exec', 'jazzy', *args)
    end

    # Copy all extra resources
    def copy_extra_resources(config)
        html_resources_path = config["output"]
        _copy_extra_resources(html_resources_path)

        docset_resources_path = docset_resources_path(config)
        if docset_resources_path.length > 0
            _copy_extra_resources(docset_resources_path)
        end
    end

    # Private: Copies all the extra resources to the given `to_path`
    def _copy_extra_resources(to_path)
        FileUtils.cp('readme-banner.jpg', to_path)
        FileUtils.cp_r('docs/resources', to_path)
    end

    # Rebuilds the DocSet archive
    def rebuild_docset_archive(config)
        docset_path = docset_path(config)
        if not File.directory?(docset_path)
            return
        end

        docsets_path = docsets_path(config)
        docset_name = docset_name(config)

        full_archive_name = docset_name + ".tgz"
        archive_path =  File.join(docsets_path, full_archive_name)

        # Remove the existing archive
        File.file?(archive_path) and FileUtils.rm(archive_path)

        # Create a new archive in the same location
        Dir.chdir(docsets_path) do
            system(
                'tar',
                '--exclude=\'.DS_Store\'',
                '-czf',
                full_archive_name,
                full_docset_name(config)
            )
        end
    end

    # The path to the temp directory used for publishing
    def publish_tmp_dir_path()
        return File.join(Dir.tmpdir(), "com.spotify.HubFramework", "docs", SecureRandom.uuid)
    end

    # Prepare the temporary directory used for publishing
    def prepare_publish_dir(path)
        cleanup_publish_dir(path)
        FileUtils.mkdir_p(path)
    end

    # Cleanup a publish dir at the given path
    def cleanup_publish_dir(path)
        FileUtils.rm_rf(path, secure: true)
    end

    # Remove some files, copy some other files, commit and push!
    def publish_docs(tmp_dir, repo_dir, branch, docs_dir, for_commit)
        # Remove all files in the repo, otherwise we might get lingering files that aren’t
        # generated by jazzy anymore. This won’t remove any dotfiles, which is intentional.
        FileUtils.rm_rf(Dir.glob("#{repo_dir}/*"), secure: true)

        # Copy all of the newly generated documentation files that we want to publish.
        FileUtils.cp_r("#{docs_dir}/.", repo_dir)

        # Create a nifty commit message.
        commit_msg_path = File.join(tmp_dir, 'commit_msg')
        create_commit_msg(commit_msg_path, for_commit)

        # Stage, commit and push!
        execute_git(repo_dir, 'add', '.')
        execute_git(repo_dir, 'commit', '--quiet', '-F', commit_msg_path)
        execute_git(repo_dir, 'push', '--quiet', 'origin', branch)
    end

    # Create a commit message for a given commit
    def create_commit_msg(commit_msg_path, for_commit)
        File.open(commit_msg_path, 'w') do |file|
            file.puts("Automatic documentation update\n")
            file.puts("- Generated for #{for_commit}.")
        end
    end

    # Clone a repo to the given destination
    def git_clone_repo(repo, branch, destination)
        system('git', 'clone', '--quiet', '-b', branch, repo, destination)
    end

    # Whether the given repo contains changes
    def git_repo_has_changes(repo_dir)
        return true
    end

    # Returns the current HEAD’s git hash
    def git_head_hash(repo_dir)
        return `git -C "#{repo_dir}" rev-parse HEAD`
    end

    # Executes the given git commands and options (*args) in the given repo_dir
    def execute_git(repo_dir, *args)
        system('git', '-C', repo_dir, *args)
    end

    # Returns the location where DocSets are placed
    def docsets_path(config)
        return File.join(config["output"], "docsets")
    end

    # Returns the name (exluding ) of the DocSet
    def docset_name(config)
        return config["module"]
    end

    # Returns the full name (including extension) of the DocSet
    def full_docset_name(config)
        return docset_name(config) + ".docset"
    end

    # Returns the path to the DocSet
    def docset_path(config)
        full_docset_name = full_docset_name(config)
        return File.join(docsets_path(config), full_docset_name)
    end

    # Returns the path to the DocSet’s resources directory
    def docset_resources_path(config)
        return File.join(docset_path(config), "Contents", "Resources", "Documents")
    end

end

desc "Generate and publish the documentation"
task :docs => 'docs:all'
