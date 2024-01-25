//
// Copyright (c) Nathan Tannar
//

#ifndef view_visitor_h
#define view_visitor_h

#include <TargetConditionals.h>

extern void _swift_visit_EnvironmentKey(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_ViewTraitKey(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_View(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_ViewModifier(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_MultiView(void *_Nonnull content, void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

#if TARGET_OS_IOS || TARGET_OS_TV

extern void _swift_visit_UIViewRepresentable(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_UIViewControllerRepresentable(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

#endif

#if TARGET_OS_OSX

extern void _swift_visit_NSViewRepresentable(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_NSViewControllerRepresentable(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

#endif

#endif /* view_visitor_h */
