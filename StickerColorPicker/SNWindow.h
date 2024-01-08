//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Oct 25 2017 03:49:04).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import <AppKit/NSWindow.h>

//#import "NSTextViewDelegate-Protocol.h"

@class NSButton, NSString, NSTextField, NSTextView, SNSpineView;

@interface SNWindow : NSWindow // <NSTextViewDelegate>
{
    double _expandFrameY;
    SNSpineView *_spineView;
    NSTextField *_titleTextField;
    NSButton *_closeButton;
    NSButton *_zoomButton;
    NSButton *_collapseButton;
    NSTextView *_textView;
    struct CGSize _expandedFrameSize;
}

@property NSTextView *textView; // @synthesize textView=_textView;
@property __weak NSButton *collapseButton; // @synthesize collapseButton=_collapseButton;
@property __weak NSButton *zoomButton; // @synthesize zoomButton=_zoomButton;
@property __weak NSButton *closeButton; // @synthesize closeButton=_closeButton;
@property __weak NSTextField *titleTextField; // @synthesize titleTextField=_titleTextField;
@property __weak SNSpineView *spineView; // @synthesize spineView=_spineView;
@property double expandFrameY; // @synthesize expandFrameY=_expandFrameY;
@property struct CGSize expandedFrameSize; // @synthesize expandedFrameSize=_expandedFrameSize;
//- (void).cxx_destruct;
- (void)setTextString:(id)arg1;
- (void)setTextFont:(id)arg1;
- (id)printingTextStorage;
- (id)richTextFormatDirectoryFileWrapper;
- (id)richTextFormatData;
- (id)plainTextData;
- (void)orderFrontLinkPanel;
- (void)scrollToSelection;
- (id)selectedString;
- (struct _NSRange)selectedRange;
- (void)replaceAllOccurrencesOfString:(id)arg1 withString:(id)arg2 replacementCount:(unsigned long long *)arg3 options:(unsigned long long)arg4;
- (void)replaceSelectedStringWithString:(id)arg1;
- (struct _NSRange)findString:(id)arg1 options:(unsigned long long)arg2 wrap:(BOOL)arg3 ignoreSelection:(BOOL)arg4;
- (void)useCurrentSettingsAsDefault;
- (void)updateTitle;
- (void)setTranslucent:(BOOL)arg1;
- (BOOL)isTranslucent;
- (void)setFloating:(BOOL)arg1;
- (BOOL)isFloating;
- (BOOL)isMovableByWindowBackground;
- (void)toggleTranslucent:(id)arg1;
- (void)toggleFloatingMenuAction:(id)arg1;
- (struct CGRect)windowWillUseStandardFrame:(id)arg1 defaultFrame:(struct CGRect)arg2;
- (BOOL)validateMenuItem:(id)arg1;
- (BOOL)isDocumentEdited;
- (unsigned long long)collectionBehavior;
- (BOOL)isContentEmpty;
- (void)loadFromFile:(id)arg1;
- (void)saveToFile:(id)arg1;
- (unsigned long long)spellCheckingTypes;
- (void)setSpellCheckingTypes:(unsigned long long)arg1;
- (BOOL)textView:(id)arg1 shouldChangeTextInRange:(struct _NSRange)arg2 replacementString:(id)arg3;
- (void)loadContentFromPasteboard:(id)arg1;
- (void)deactivateSpine;
- (void)activateSpine;
- (void)mouseDragged:(id)arg1;
- (BOOL)isCollapsed;
- (void)performZoom:(id)arg1;
- (void)miniaturize:(id)arg1;
- (void)performMiniaturize:(id)arg1;
- (void)performClose:(id)arg1;
- (double)animationResizeTime:(struct CGRect)arg1;
- (void)resignKeyWindow;
- (void)becomeKeyWindow;
- (BOOL)canBecomeKeyWindow;
- (BOOL)canBecomeMainWindow;
- (void)updateSpineToolTip:(id)arg1;
- (void)hideZoomButtonIfNeeded;
- (void)updateExpandedFrameSizeIfNeeded;
- (void)refreshControlButtons;
- (id)spineTitle;
- (void)setSpineTitle:(id)arg1;
- (void)setSpineColor:(id)arg1 stickyColor:(id)arg2;
- (void)awakeFromNib;

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

