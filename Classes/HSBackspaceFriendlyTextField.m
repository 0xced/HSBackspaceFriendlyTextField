//
//  MyTextField.m
//  HSBackspaceFriendlyTextField
//
//  Created by BJ Homer on 10/29/11.
//  Copyright (c) 2011. All rights reserved.
//

#import "HSBackspaceFriendlyTextField.h"
#import <objc/runtime.h>


static NSString * const SubclassName = @"HSBackspaceNotifyingFieldEditor";

static void *BackwardDeleteTargetKey = &BackwardDeleteTargetKey;


@implementation HSBackspaceFriendlyTextField

+ (void)load {
	Class UIFieldEditor = NSClassFromString(@"UIFieldEditor");
	Method deleteBackward = class_getInstanceMethod(UIFieldEditor, @selector(deleteBackward));
	Method hs_deleteBackward = class_getInstanceMethod(UIFieldEditor, @selector(hs_deleteBackward));
	if (deleteBackward && hs_deleteBackward && strcmp(method_getTypeEncoding(deleteBackward), method_getTypeEncoding(hs_deleteBackward)) == 0) {
		method_exchangeImplementations(deleteBackward, hs_deleteBackward);
	}
}

- (void)my_willDeleteBackward {
	
	// Check if the cursor is at the start of the field.
	UITextRange *selectedRange = self.selectedTextRange;
	if (selectedRange.empty && [selectedRange.start isEqual:self.beginningOfDocument]) {
		
		// We're reusing the existing delegate method, since that's where other keypress events
		// on a UITextField are usually tracked. Note that since no actual change is being made,
		// we're ignoring the return value.
		if ([self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
			[self.delegate textField:self shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
		}
	}
}

- (BOOL)becomeFirstResponder {
	BOOL shouldBecome = [super becomeFirstResponder];
	if (shouldBecome == NO) {
		return NO;
	}
	
	id fieldEditor = [self valueForKey:@"fieldEditor"];
	
	if (fieldEditor) {
		objc_setAssociatedObject(fieldEditor, BackwardDeleteTargetKey, self, OBJC_ASSOCIATION_ASSIGN);
	}
	
	return YES;
}

- (BOOL)resignFirstResponder {
	BOOL shouldResign =  [super resignFirstResponder];
	if (shouldResign == NO) {
		return NO;
	}
	
	id fieldEditor = [self valueForKey:@"fieldEditor"];
					  
	if (fieldEditor) {
		objc_setAssociatedObject(fieldEditor, BackwardDeleteTargetKey, nil, OBJC_ASSOCIATION_ASSIGN);
	}
	return YES;
}

@end

WEAK_IMPORT_ATTRIBUTE
@interface UIFieldEditor : UIView
@end

@implementation UIFieldEditor (HSBackspaceFriendlyTextField)

- (void)hs_deleteBackward {
	
	HSBackspaceFriendlyTextField *textField = objc_getAssociatedObject(self, BackwardDeleteTargetKey);
	[textField my_willDeleteBackward];
	
	// Swizzled method, this actually calls the original IMP
	[self hs_deleteBackward];
}

@end
