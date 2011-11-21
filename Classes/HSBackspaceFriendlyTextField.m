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

static void (*UIFieldEditor_deleteBackward)(id, SEL) = NULL;

static void deleteBackward(id self, SEL _cmd) {
	
	HSBackspaceFriendlyTextField *textField = objc_getAssociatedObject(self, BackwardDeleteTargetKey);
	[textField my_willDeleteBackward];
	
	UIFieldEditor_deleteBackward(self, _cmd);
}


@implementation HSBackspaceFriendlyTextField

+ (void)load {
	Class UIFieldEditor = NSClassFromString(@"UIFieldEditor");
	Method deleteBackwardMethod = class_getInstanceMethod(UIFieldEditor, @selector(deleteBackward));
	Method loadMethod = class_getClassMethod(self, _cmd);
	if (deleteBackwardMethod && loadMethod && strcmp(method_getTypeEncoding(deleteBackwardMethod), method_getTypeEncoding(loadMethod)) == 0) {
		UIFieldEditor_deleteBackward = (void (*)(id, SEL))method_getImplementation(deleteBackwardMethod);
		method_setImplementation(deleteBackwardMethod, (IMP)deleteBackward);
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
