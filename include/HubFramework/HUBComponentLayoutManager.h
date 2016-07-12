#import <CoreGraphics/CoreGraphics.h>
#import "HUBComponentLayoutTraits.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enum describing various logical content edges
 *
 *  A content edge is where the rendering of content "stops", such as at the screen edge or when
 *  an area covered by a navigation bar begins. Content edges have a 1:1 mapping to content insets.
 */
typedef NS_ENUM(NSUInteger, HUBComponentLayoutContentEdge) {
    /// The top content edge, usually where a navigation bar begins
    HUBComponentLayoutContentEdgeTop,
    /// The right content edge, usually at the screen edge
    HUBComponentLayoutContentEdgeRight,
    /// The bottom content edge, usually where a tab bar begins or at the screen edge
    HUBComponentLayoutContentEdgeBottom,
    /// The left content edge, usually at the screen edge
    HUBComponentLayoutContentEdgeLeft
};

/**
 *  Protocol implemented by an object that acts as a layout manager for components in an instance of the Hub Framework
 *
 *  You implement this protocol in a single custom object and inject it when setting up the application's `HUBManager`.
 *  The responsibility of a component layout manager is to compute margins between various components and content edges.
 *
 *  A layout manager is always given a set of layout traits for the component(s) in question, to be able to make good
 *  decisions on what margins to use. For more information about layout traits; see `HUBComponentLayoutTrait`.
 */
@protocol HUBComponentLayoutManager <NSObject>

/**
 *  Return the margin to use between a component with a set of layout traits and a content edge
 *
 *  @param layoutTraits The layout traits of the component to compute a margin for
 *  @param contentEdge The content edge to compute the margin to
 *
 *  This method will be called by the Hub Framework when a component is about to be placed close to a content edge.
 *  See `HUBComponentLayoutTrait` and `HUBComponentLayoutContentEdge` for more information.
 */
- (CGFloat)marginBetweenComponentWithLayoutTraits:(NSSet<HUBComponentLayoutTrait *> *)layoutTraits
                                   andContentEdge:(HUBComponentLayoutContentEdge)contentEdge;

/**
 *  Return the vertical margin to use between a body component and a header component
 *
 *  @param layoutTraits The layout traits for the body component
 *  @param headerLayoutTraits The layout traits for the header component
 *
 *  This method will be called by the Hub Framework when a component is about to be placed on the first row below a header
 *  component. See `HUBComponentLayoutTrait` for more information.
 */
- (CGFloat)verticalMarginBetweenComponentWithLayoutTraits:(NSSet<HUBComponentLayoutTrait *> *)layoutTraits
                       andHeaderComponentWithLayoutTraits:(NSSet<HUBComponentLayoutTrait *> *)headerLayoutTraits;

/**
 *  Return the horizontal margin to use between two body components
 *
 *  @param layoutTraits The layout traits for the component to determine the margin for
 *  @param precedingComponentLayoutTraits The layout traits for the component that precedes the current one horizontally
 *
 *  The Hub Framework will only call this method once for a given component pair, so the returned value should be the absolute
 *  margin between the components, rather than a half value. See `HUBComponentLayoutTrait` for more information.
 */
- (CGFloat)horizontalMarginForComponentWithLayoutTraits:(NSSet<HUBComponentLayoutTrait *> *)layoutTraits
                         precedingComponentLayoutTraits:(NSSet<HUBComponentLayoutTrait *> *)precedingComponentLayoutTraits;

/**
 *  Return the vertical margin to use between two body components
 *
 *  @param layoutTraits The layout traits for the compone to determine the margin for
 *  @param precedingComponentLayoutTraits The layout traits for the component that precedes the current one vertically
 *
 *  The Hub Framework will only call this method once for a given component pair, so the returned value should be the absolute
 *  margin between the components, rather than a half value. See `HUBComponentLayoutTrait` for more information.
 */
- (CGFloat)verticalMarginForComponentWithLayoutTraits:(NSSet<HUBComponentLayoutTrait *> *)layoutTraits
                       precedingComponentLayoutTraits:(NSSet<HUBComponentLayoutTrait *> *)precedingComponentLayoutTraits;

/**
 *  Checks if two components could be horizontally adjacent
 *
 *  @param layoutTraits                   The layout traits for the component that should (or not) be placed next to its preceding one
 *  @param precedingComponentLayoutTraits The layout traits for the component that precedes the current one horizontally
 *
 *  @return Whether a component the provided layoutTraits should (or not) be placed next to preceding component 
 *          with the provided precedingComponentLayoutTraits
 */
- (BOOL)shouldLayoutComponentWithLayoutTraits:(NSSet<HUBComponentLayoutTrait *> *)layoutTraits
  horizontallyNextToComponentWithLayoutTraits:(NSSet<HUBComponentLayoutTrait *> * _Nullable)precedingComponentLayoutTraits;

/**
 *  Checks if component could be part of a layout that requires centering of adjacent components
 *
 *  @param layoutTraits The layout traits for the component that should (or not) be centered
 *
 *  @return Whether a component the provided layout traits should (or not) be centered
 */
- (BOOL)shouldCenterHorizontallyComponentWithLayoutTraits:(NSSet<HUBComponentLayoutTrait *> *)layoutTraits;

@end

NS_ASSUME_NONNULL_END
