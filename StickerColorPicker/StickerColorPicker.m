//
//  StickerColorPicker.m
//  StickerColorPicker
//
//  Created by Brian "Shishkabibal" on 12/9/23.
//  Copyright (c) 2023 Brian "Shishkabibal". All rights reserved.
//

#pragma mark - Library/Header Imports

@import AppKit;

#import <objc/runtime.h>

#import "SNWindow.h"
#import "SNUtility.h"
#import "SNDocument.h"
#import "SNMenuController.h"

#import "ZKSwizzle.h"

#include <os/log.h>
#define DLog(N, ...) os_log_with_type(os_log_create("com.shishkabibal.StickerColorPicker", "DEBUG"),OS_LOG_TYPE_DEFAULT,N ,##__VA_ARGS__)


#pragma mark - Global Variables

NSBundle* bundle;

static NSString* const preferencesSuiteName = @"com.shishkabibal.StickerColorPicker";


#pragma mark - Popover Interfaces

@interface Popover: NSObject <NSPopoverDelegate>

@property (strong, nonatomic) NSPopover* popover;
@property (strong, nonatomic) NSWindow* window;
@property (strong, nonatomic) NSColorWell* stickyWell;
@property (strong, nonatomic) NSColorWell* spineWell;
@property (strong, nonatomic) NSColorWell* highlightWell;
@property (strong, nonatomic) NSColorWell* controlWell;

- (instancetype)initWithPopover:(NSPopover*)popover
                         window:(NSWindow*)window
                     stickyWell:(NSColorWell*)stickyWell
                      spineWell:(NSColorWell*)spineWell
                  highlightWell:(NSColorWell*)highlightWell
                    controlWell:(NSColorWell*)controlWell;

@end

@interface PopoversManager: NSObject

@property (strong, nonatomic) NSMutableArray<Popover*>* popovers;

+ (instancetype)sharedManager;
- (void)addPopover:(Popover*)popover;
- (void)removePopover:(Popover*)popover;

@end


#pragma mark - Popover Implementations

@implementation Popover

// Handles Popover init
- (instancetype)initWithPopover:(NSPopover*)popover window:(NSWindow*)window stickyWell:(NSColorWell*)stickyWell spineWell:(NSColorWell*)spineWell highlightWell:(NSColorWell*)highlightWell controlWell:(NSColorWell*)controlWell {
    self = [super init];
    if (self) {
        _popover = popover;
        _window = window;
        _stickyWell = stickyWell;
        _spineWell = spineWell;
        _highlightWell = highlightWell;
        _controlWell = controlWell;
        
        _popover.delegate = self;
    }
    return self;
}

// Handles PopoversManager cleanup on Popover close
- (void)popoverDidClose:(NSNotification*)notification {
    // Post a notification when the popover closes
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PopoverWillCloseNotification" object:self];
}

@end

@implementation PopoversManager

// Handles PopoversManager init
+ (instancetype)sharedManager {
    static PopoversManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _popovers = [NSMutableArray array];
        
        // Observe the notification for popover closure
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(popoverWillCloseNotification:)
                                                     name:@"PopoverWillCloseNotification"
                                                   object:nil];
    }
    return self;
}

// Handles adding Popover to PopoversManager
- (void)addPopover:(Popover*)popover {
    // Add popover (NSPopover) to window (NSWindow)
    NSWindow* window = popover.window;
    NSRect belowWindowRect = NSMakeRect(window.frame.origin.x, window.frame.origin.y - 5, window.frame.size.width, 0);
    [popover.popover showRelativeToRect:belowWindowRect ofView:window.contentView preferredEdge:NSRectEdgeMaxY];
    
    // Add Popover to PopoversManager
    [self.popovers addObject:popover];
}

// Handles removing Popover from PopoversManager
- (void)removePopover:(Popover*)popover {
    // Remove popover (NSPopover) from window (NSWindow)
    [popover.popover close];
    
    // Remove Popover from PopoversManager
    [self.popovers removeObject:popover];
}

- (Popover*)popoverForWindow:(NSWindow*)window {
    for (Popover* popover in self.popovers) {
        if (popover.window == window) {
            return popover;
        }
    }
    return nil;
}

- (void)popoverWillCloseNotification:(NSNotification*)notification {
    Popover* closedPopover = notification.object;
    if (closedPopover) {
        [self removePopover:closedPopover];
    }
}

- (void)dealloc {
    // Remove the observer in dealloc to avoid memory leaks
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


#pragma mark - Color Interfaces

@interface Color: NSObject

@property (nonatomic, assign) int tag;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, strong) NSColor* stickyColor;
@property (nonatomic, strong) NSColor* spineColor;
@property (nonatomic, strong) NSColor* highlightColor;
@property (nonatomic, strong) NSColor* controlColor;

- (instancetype)initWithTag:(int)tag
                       name:(NSString*)name
                stickyColor:(NSColor*)stickyColor
                 spineColor:(NSColor*)spineColor
             highlightColor:(NSColor*)highlightColor
               controlColor:(NSColor*)controlColor;

@end

@interface ColorsManager: NSObject

@property (nonatomic, strong) NSMutableArray<Color*>* colorCollection;

+ (instancetype)sharedManager;
- (Color*)getColorByName:(NSString*)name;
- (NSArray<Color*>*)sortedColorsByTag;
- (NSArray<NSColor*>*)sortedValuesForKey:(NSString*)key;

@end


#pragma mark - Color Implementations

@implementation Color

- (instancetype)initWithTag:(int)tag
                      name:(NSString*)name
               stickyColor:(NSColor*)stickyColor
                spineColor:(NSColor*)spineColor
           highlightColor:(NSColor*)highlightColor
             controlColor:(NSColor*)controlColor {
    self = [super init];
    if (self) {
        _tag = tag;
        _name = [name copy];
        _stickyColor = stickyColor;
        _spineColor = spineColor;
        _highlightColor = highlightColor;
        _controlColor = controlColor;
    }
    return self;
}

@end

@implementation ColorsManager

+ (instancetype)sharedManager {
    static ColorsManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        sharedManager.colorCollection = [NSMutableArray array];
        
        // Add default colors
        Color *yellowColor = [[Color alloc] initWithTag:1
                                                   name:@"Yellow"
                                            stickyColor:[NSColor colorNamed:@"StickiesYellowColor"]
                                             spineColor:[NSColor colorNamed:@"StickiesSpineYellowColor"]
                                         highlightColor:[NSColor colorNamed:@"StickiesHighlightYellowColor"]
                                           controlColor:[NSColor colorNamed:@"StickiesControlYellowColor"]];
        [sharedManager.colorCollection addObject:yellowColor];
        
        Color *blueColor = [[Color alloc] initWithTag:2
                                                 name:@"Blue"
                                          stickyColor:[NSColor colorNamed:@"StickiesBlueColor"]
                                           spineColor:[NSColor colorNamed:@"StickiesSpineBlueColor"]
                                       highlightColor:[NSColor colorNamed:@"StickiesHighlightBlueColor"]
                                         controlColor:[NSColor colorNamed:@"StickiesControlBlueColor"]];
        [sharedManager.colorCollection addObject:blueColor];
        
        Color *greenColor = [[Color alloc] initWithTag:3
                                                  name:@"Green"
                                           stickyColor:[NSColor colorNamed:@"StickiesGreenColor"]
                                            spineColor:[NSColor colorNamed:@"StickiesSpineGreenColor"]
                                        highlightColor:[NSColor colorNamed:@"StickiesHighlightGreenColor"]
                                          controlColor:[NSColor colorNamed:@"StickiesControlGreenColor"]];
        [sharedManager.colorCollection addObject:greenColor];
        
        Color *pinkColor = [[Color alloc] initWithTag:4
                                                 name:@"Pink"
                                          stickyColor:[NSColor colorNamed:@"StickiesPinkColor"]
                                           spineColor:[NSColor colorNamed:@"StickiesSpinePinkColor"]
                                       highlightColor:[NSColor colorNamed:@"StickiesHighlightPinkColor"]
                                         controlColor:[NSColor colorNamed:@"StickiesControlPinkColor"]];
        [sharedManager.colorCollection addObject:pinkColor];
        
        Color *purpleColor = [[Color alloc] initWithTag:5
                                                   name:@"Purple"
                                            stickyColor:[NSColor colorNamed:@"StickiesPurpleColor"]
                                             spineColor:[NSColor colorNamed:@"StickiesSpinePurpleColor"]
                                         highlightColor:[NSColor colorNamed:@"StickiesHighlightPurpleColor"]
                                           controlColor:[NSColor colorNamed:@"StickiesControlPurpleColor"]];
        [sharedManager.colorCollection addObject:purpleColor];
        
        Color *grayColor = [[Color alloc] initWithTag:6
                                                 name:@"Gray"
                                          stickyColor:[NSColor colorNamed:@"StickiesGrayColor"]
                                           spineColor:[NSColor colorNamed:@"StickiesSpineGrayColor"]
                                       highlightColor:[NSColor colorNamed:@"StickiesHighlightGrayColor"]
                                         controlColor:[NSColor colorNamed:@"StickiesControlGrayColor"]];
        [sharedManager.colorCollection addObject:grayColor];
        
        Color *orangeColor = [[Color alloc] initWithTag:7
                                                   name:@"Orange"
                                            stickyColor:[NSColor colorWithRed:(254/255.0f) green:(203/255.0f) blue:(156/255.0f) alpha:1.0]
                                             spineColor:[NSColor colorWithRed:(255/255.0f) green:(155/255.0f) blue:(62/255.0f) alpha:1.0]
                                         highlightColor:[NSColor colorWithRed:(188/255.0f) green:(91/255.0f) blue:(2/255.0f) alpha:1.0]
                                           controlColor:[NSColor colorWithRed:(218/255.0f) green:(109/255.0f) blue:(6/255.0f) alpha:1.0]];
        [sharedManager.colorCollection addObject:orangeColor];
        
        Color *blackColor = [[Color alloc] initWithTag:8
                                                   name:@"Black"
                                            stickyColor:[NSColor colorWithRed:(41/255.0f) green:(42/255.0f) blue:(47/255.0f) alpha:1.0]
                                             spineColor:[NSColor colorWithRed:(48/255.0f) green:(50/255.0f) blue:(56/255.0f) alpha:1.0]
                                         highlightColor:[NSColor colorWithRed:(130/255.0f) green:(134/255.0f) blue:(148/255.0f) alpha:1.0]
                                           controlColor:[NSColor colorWithRed:(129/255.0f) green:(139/255.0f) blue:(150/255.0f) alpha:1.0]];
        [sharedManager.colorCollection addObject:blackColor];
        
//        Color *customColor = [[Color alloc] initWithTag:9
//                                                   name:@"Custom..."
//                                            stickyColor:[NSColor colorWithRed:(255/255.0f) green:(255/255.0f) blue:(255/255.0f) alpha:1.0]
//                                             spineColor:[NSColor colorWithRed:(255/255.0f) green:(255/255.0f) blue:(255/255.0f) alpha:1.0]
//                                         highlightColor:[NSColor colorWithRed:(255/255.0f) green:(255/255.0f) blue:(255/255.0f) alpha:1.0]
//                                           controlColor:[NSColor colorWithRed:(255/255.0f) green:(255/255.0f) blue:(255/255.0f) alpha:1.0]];
//        [sharedManager.colorCollection addObject:customColor];
    });
    return sharedManager;
}

- (Color*)getColorByName:(NSString*)name {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    NSArray<Color*>* filteredColors = [self.colorCollection filteredArrayUsingPredicate:predicate];

    if (filteredColors.count > 0) {
        return filteredColors[0];
    } else {
        return nil; // Color not found
    }
}

- (NSArray<Color*>*)sortedColorsByTag {
    return [self.colorCollection sortedArrayUsingComparator:^NSComparisonResult(Color* a, Color* b) {
        return [@(a.tag) compare:@(b.tag)];
    }];
}

- (NSArray<NSColor*>*)sortedValuesForKey:(NSString*)key {
    NSArray<Color*>* sortedColors = [self sortedColorsByTag];
    NSArray<NSColor*>* values = [sortedColors valueForKey:key];
    return values;
}

@end


#pragma mark - Main Interface

@interface StickerColorPicker: NSObject

+ (instancetype)sharedInstance;

@end

StickerColorPicker* plugin;


#pragma mark - Main Implementation

@implementation StickerColorPicker

+ (StickerColorPicker*)sharedInstance {
    static StickerColorPicker* plugin = nil;
    
    if (!plugin)
        plugin = [[StickerColorPicker alloc] init];
    
    return plugin;
}

// Called on MacForge plugin initialization
+ (void)load {
    // Create plugin singleton + bundle
    plugin = [StickerColorPicker sharedInstance];
    
    // Register to finished launching notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    // Log loading
    NSUInteger major = [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
    NSUInteger minor = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    DLog("%{public}@: Loaded (%{public}@ - macOS %ld.%ld)", [self className], [[NSBundle mainBundle] bundleIdentifier], (long)major, (long)minor);
}

// Finished launching notification
+ (void)applicationDidFinishLaunching:(NSNotification*)notification {
    // Unregister from finished launching notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    bundle = [NSBundle bundleWithIdentifier:preferencesSuiteName];
}

@end


#pragma mark - Swizzle Handling

ZKSwizzleInterface(BS_SNMenuController, SNMenuController, NSObject)
@implementation BS_SNMenuController

- (void)setColorMenu:(NSMenu*)colorMenu {
//    // Make room for black menuItem above gray menuItem
//    NSArray* colorMenuItems = [colorMenu itemArray]; // NSMenuItems array
//    NSMenuItem* origGrayMenuItem = [colorMenuItems lastObject]; // gray menuItem is last NSMenuItem
//    NSMenuItem* cloneGrayMenuItem = [[NSMenuItem alloc] initWithTitle:@"Gray" action:@selector(clickColorMenuItem:) keyEquivalent:@"7"];
//    [cloneGrayMenuItem setTag:6];
//    [cloneGrayMenuItem setTarget:self];
//    [colorMenu removeItem:origGrayMenuItem];
//    [colorMenu addItem:cloneGrayMenuItem];
    
    // Run setColorMenu with original colorMenu
    ZKOrig(void, colorMenu);
    
    // Call populateColorMenuSwatches early
    // (NOTE: sets original 6 menuItem swatches before adding new menuItems)
    [self populateColorMenuSwatches];
    
    // Add new orange menuItem to top of menu
    // (NOTE: can add up to 6 new menuItems in idx 0-5 to colorMenu before needing to repeat pattern d/t populateColorMenuSwatches limit)
    NSMenuItem* orangeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Orange" action:@selector(clickColorMenuItem:) keyEquivalent:@"0"];
    [orangeMenuItem setTag:7]; // NOTE: must match idx in SNUtility sorted arrays
    [orangeMenuItem setTarget:self];
    [colorMenu insertItem:orangeMenuItem atIndex:0];
    
    // Add new black menuItem below orange menuItem (temporarily)
    NSMenuItem* blackMenuItem = [[NSMenuItem alloc] initWithTitle:@"Black" action:@selector(clickColorMenuItem:) keyEquivalent:@"7"];
    [blackMenuItem setTag:8];
    [blackMenuItem setTarget:self];
    [colorMenu insertItem:blackMenuItem atIndex:1]; // will handle actual position after color swatch set
    
    // Add new custom menuItem to bottom of menu
    NSMenuItem* customMenuItem = [[NSMenuItem alloc] initWithTitle:@"Custom..." action:@selector(clickColorMenuItem:) keyEquivalent:@"8"];
    NSImage* customColorSwatch = [NSImage imageNamed:@"CustomColorSwatch"]; // NOTE: this is an unused asset included by Apple
    [customMenuItem setImage:customColorSwatch];
    [customMenuItem setTarget:self]; // TODO: comment out to disable while WIP
    [colorMenu addItem:customMenuItem]; // added to bottom bc doesn't rely on populateColorMenuSwatches
    
    // Run setColorMenu with modified colorMenu
    ZKOrig(void, colorMenu);
    
    // Call populateColorMenuSwatches early
    // (NOTE: sets any new 6 menuItem swatches)
    [self populateColorMenuSwatches];
    
    // Move new menuItem to desired position outside of populateColorMenuSwatches range
    // (NOTE: don't need to run ZKOrig again after this)
    [colorMenu removeItem:blackMenuItem];
    [colorMenu insertItem:blackMenuItem atIndex:7];
}

- (void)clickColorMenuItem:(NSMenuItem*)menuItem {
    NSWindow* window = [NSApp keyWindow];
    PopoversManager* popoversManager = [PopoversManager sharedManager];
    Popover* preexistingPopover = [popoversManager popoverForWindow:window];
    
    if ([[menuItem title] isEqual:@"Custom..."]) {
        // Setup popover
        NSPopover* popover = [[NSPopover alloc] init];
        popover.behavior = NSPopoverBehaviorTransient;
        NSView* popoverView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 150, 160)];
        popover.contentViewController = [[NSViewController alloc] init];
        popover.contentViewController.view = popoverView;
        
        // Setup labels
        NSTextField* stickyLabel = [self labelWithText:@"Sticky"];
        NSTextField* spineLabel = [self labelWithText:@"Spine"];
        NSTextField* highlightLabel = [self labelWithText:@"Highlight"];
        NSTextField* controlLabel = [self labelWithText:@"Control"];
        
        // Setup color wells
        NSColorWell* stickyWell;
        NSColorWell* spineWell;
        NSColorWell* highlightWell;
        NSColorWell* controlWell;
        
        if (@available(macOS 13.0, *)) {
            stickyWell = [NSColorWell colorWellWithStyle:NSColorWellStyleMinimal];
            spineWell = [NSColorWell colorWellWithStyle:NSColorWellStyleMinimal];
            highlightWell = [NSColorWell colorWellWithStyle:NSColorWellStyleMinimal];
            controlWell = [NSColorWell colorWellWithStyle:NSColorWellStyleMinimal];
        } else {
            stickyWell = [[NSColorWell alloc] init];
            spineWell = [[NSColorWell alloc] init];
            highlightWell = [[NSColorWell alloc] init];
            controlWell = [[NSColorWell alloc] init];
        }
        
        SNDocument* document = window.windowController.document;
        [stickyWell setColor:[document stickyColor]];
        [spineWell setColor:[document spineColor]];
        [highlightWell setColor:[document highlightColor]];
        [controlWell setColor:[document controlColor]];
        
        [stickyWell setTag:0];
        [stickyWell setTarget:self];
        [stickyWell setAction:@selector(colorWellDidChange:)];
        
        [spineWell setTag:1];
        [spineWell setTarget:self];
        [spineWell setAction:@selector(colorWellDidChange:)];
        
        [highlightWell setTag:2];
        [highlightWell setTarget:self];
        [highlightWell setAction:@selector(colorWellDidChange:)];
        
        [controlWell setTag:3];
        [controlWell setTarget:self];
        [controlWell setAction:@selector(colorWellDidChange:)];
        
        // Setup grid
        NSArray* gridRows = @[
            @[stickyLabel, stickyWell],
            @[spineLabel, spineWell],
            @[highlightLabel, highlightWell],
            @[controlLabel, controlWell]
        ];
        NSGridView *gridView = [NSGridView gridViewWithViews:gridRows];
        gridView.translatesAutoresizingMaskIntoConstraints = NO;
        gridView.rowSpacing = 10.0;
        gridView.columnSpacing = 20.0;
        [popoverView addSubview:gridView];
        
        [gridView.centerXAnchor constraintEqualToAnchor:popoverView.centerXAnchor].active = YES;
        [gridView.centerYAnchor constraintEqualToAnchor:popoverView.centerYAnchor].active = YES;
        [gridView.topAnchor constraintGreaterThanOrEqualToAnchor:popoverView.topAnchor].active = YES;
        [gridView.bottomAnchor constraintLessThanOrEqualToAnchor:popoverView.bottomAnchor].active = YES;
        
        [gridView columnAtIndex:0].xPlacement = NSGridCellPlacementTrailing;
        gridView.rowAlignment = NSGridRowAlignmentFirstBaseline;
        
        // Open popover if closed & close popover if opened
        if (preexistingPopover) {
            [popoversManager removePopover:preexistingPopover];
        } else {
            [popoversManager addPopover:[[Popover alloc] initWithPopover:popover window:window stickyWell:stickyWell spineWell:spineWell highlightWell:highlightWell controlWell:controlWell]];
        }
    } else {
        // // Close popover if opened
        // [popoversManager removePopover:preexistingPopover];
        
        ColorsManager *colorsManager = [ColorsManager sharedManager];
        Color* color = [colorsManager getColorByName:[menuItem title]];
        
        [self customColorDidChange:color];
        
        if (preexistingPopover) {
            [preexistingPopover.stickyWell setColor:[color stickyColor]];
            [preexistingPopover.spineWell setColor:[color spineColor]];
            [preexistingPopover.highlightWell setColor:[color highlightColor]];
            [preexistingPopover.controlWell setColor:[color controlColor]];
        }
        
        // // Handles user selecting original color menuItem
        // ZKOrig(void, menuItem);
    }
}

- (NSTextField*)labelWithText:(NSString*)text {
    NSTextField *label = [[NSTextField alloc] init];
    
    [label setStringValue:text];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    
    return label;
}

- (void)customColorDidChange:(Color*)customColor {
    // Get selected document
    NSWindow* window = [NSApp keyWindow];
    SNDocument* document = window.windowController.document;
        
    // Change color variables
    [document setStickyColor:[customColor stickyColor]];
    [document setSpineColor:[customColor spineColor]];
    [document setHighlightColor:[customColor highlightColor]];
    [document setControlColor:[customColor controlColor]];
    
    // Refresh window UI
    [document updateWindowColor];
}

- (void)colorWellDidChange:(NSColorWell*)colorWell {
    // Get selected document
    NSWindow* window = [NSApp keyWindow];
    SNDocument* document = window.windowController.document;
    
    // Change color variable based on tag
    if (colorWell.tag == 0) {
        [document setStickyColor:[colorWell color]];
    } else if (colorWell.tag == 1) {
        [document setSpineColor:[colorWell color]];
    } else if (colorWell.tag == 2) {
        [document setHighlightColor:[colorWell color]];
    } else if (colorWell.tag == 3) {
        [document setControlColor:[colorWell color]];
    }
    
    // Refresh window UI
    [document updateWindowColor];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem {
    // Determines if passed menuItem is enabled/disabled
    BOOL validate = ZKOrig(BOOL, menuItem);
    
    // 0 → menuItem disabled
    // 1 → menuItem enabled
    
    return validate;
}

- (void)populateColorMenuSwatches {
    // Overrides menuItem image to set color swatch (preview) for the first 6 color menuItems
    ZKOrig(void);
}

@end

ZKSwizzleInterface(BS_SNDocument, SNDocument, NSDocument)
@implementation BS_SNDocument

// // Called by:
// //  (1) [SNMenuController clickColorMenuItem] // called after ivars are changed
// //  (2) [SNDashboardStickiesImporter importFromDashboardStickiesIfNeeded]
//- (void)updateWindowColor {
//    ZKOrig(void);
//}

// // Called by: (1) [SNMenuController *Arrange*]
//- (long long)compareColor:(NSDocument*)stickyDocument {
//    // Used for comparing note colors (Window > Arrange By > Color)
//    long long compare = ZKOrig(long long, stickyDocument);
//    
//    // 1 → first passed stickyDocument color is greater than second
//    // 0 → passed stickyDocument colors are equal
//    // -1 → first passed stickyDocument color is less than second
//    
//    return compare;
//}

@end

ZKSwizzleInterface(BS_SNUtility, SNUtility, NSObject)
@implementation BS_SNUtility

// Getter accessor for sortedStickyColors
- (NSArray*)sortedStickyColors {
//    NSArray* expected = ZKOrig(NSArray*);
    ColorsManager *colorsManager = [ColorsManager sharedManager];
    return [colorsManager sortedValuesForKey:@"stickyColor"];
}

// Getter accessor for sortedSpineColors
- (NSArray*)sortedSpineColors {
//    NSArray* expected = ZKOrig(NSArray*);
    ColorsManager *colorsManager = [ColorsManager sharedManager];
    return [colorsManager sortedValuesForKey:@"spineColor"];
}

// Getter accessor for sortedHighlightColors
- (NSArray*)sortedHighlightColors {
//    NSArray* expected = ZKOrig(NSArray*);
    ColorsManager *colorsManager = [ColorsManager sharedManager];
    return [colorsManager sortedValuesForKey:@"highlightColor"];
}

// Getter accessor for sortedControlColors
- (NSArray*)sortedControlColors {
//    NSArray* expected = ZKOrig(NSArray*);
    ColorsManager *colorsManager = [ColorsManager sharedManager];
    return [colorsManager sortedValuesForKey:@"controlColor"];
}

// Getter accessor for sortedColorNames
- (NSArray*)sortedColorNames {
//    NSArray* expected = ZKOrig(NSArray*);
    ColorsManager *colorsManager = [ColorsManager sharedManager];
    return [colorsManager sortedValuesForKey:@"name"];
}

// // Called by: (1) [SNDocument initWith*]
//- (NSColor*)colorFromDictionaryRepresentation:(NSDictionary*)dictRep {
//    NSColor* color = ZKOrig(NSColor*, dictRep);
//    
//    // e.g.,
//    //  dictRep → {Red = "0.996078431372549";Green = "0.9568627450980393";Blue = "0.611764705882353";Alpha = 1;}
//    //  ↓
//    //  color → sRGB IEC61966-2.1 colorspace 0.996078 0.956863 0.611765 1
//    
//    return color;
//}

// // Called by:
// //  (1) [SNAppDelegate applicationDidFinishLaunching]
// //  (2) [SNMenuController validateMenuItem]
// //  (3) [SNMenuController exportAllNotesToFolderURL]
// //  (4) [SNUtility sortedBuiltinColorDictRepArray]
// //  (5) [SNDocument saveWindowState]
//- (NSDictionary*)dictionaryRepresentationOfColor:(NSColor*)color {
//    NSDictionary* dictRep = ZKOrig(NSDictionary*, color);
//        
//    // e.g.,
//    //  color → sRGB IEC61966-2.1 colorspace 0.996078 0.956863 0.611765 1
//    //  ↓
//    //  dictRep → {Red = "0.996078431372549";Green = "0.9568627450980393";Blue = "0.611764705882353";Alpha = 1;}
//    
//    return dictRep;
//}

// // Called by: (1) [SNAppDelegate applicationDidFinishLaunching]
//- (NSArray*)sortedBuiltinColorDictRepArray {
//    NSArray* sortedBuiltinColorDictRepArray = ZKOrig(NSArray*);
//    
// //    ({
// //        ControlColor = {Red = "0.8588235294117647";Green = "0.7725490196078432";Blue = "0.01176470588235294";Alpha = 1;};
// //        HighlightColor = {Red = "0.7372549019607844";Green = "0.6627450980392157";Blue = "0.007843137254901961";Alpha = 1;};
// //        SpineColor = {Red = "0.996078431372549";Green = "0.9176470588235294";Blue = "0.2392156862745098";Alpha = 1;};
// //        StickyColor = {Red = "0.996078431372549";Green = "0.9568627450980393";Blue = "0.611764705882353";Alpha = 1;};
// //    }, ...)
//
//    return sortedBuiltinColorDictRepArray;
//}

// // Called by:
// //  (1) [SNMenuController validateMenuItem]
// //  (2) [SNMenuController exportAllNotesToFolderURL]
// //  (3) [SNDocument compareColor]
//- (NSArray*)sortedStickyColorDictionaryRepresentations {
//    NSArray* sortedStickyColorDictRepArr = ZKOrig(NSArray*);
//        
// //    (
// //        {Red = "0.996078431372549";Green = "0.9568627450980393";Blue = "0.611764705882353";Alpha = 1;},
// //        {Red = "0.6784313725490196";Green = "0.9568627450980393";Blue = 1;Alpha = 1;},
// //        {Red = "0.6980392156862745";Green = 1;Blue = "0.6313725490196078";Alpha = 1;},
// //        {Red = 1;Green = "0.7803921568627451";Blue = "0.7803921568627451";Alpha = 1;},
// //        {Red = "0.7137254901960784";Green = "0.792156862745098";Blue = 1;Alpha = 1;},
// //        {Red = "0.9333333333333333";Green = "0.9333333333333333";Blue = "0.9333333333333333";Alpha = 1;}
// //    )
//
//    return sortedStickyColorDictRepArr;
//}

@end
