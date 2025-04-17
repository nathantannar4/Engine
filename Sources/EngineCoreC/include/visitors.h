//
// Copyright (c) Nathan Tannar
//

#ifndef view_visitor_h
#define view_visitor_h

#include <TargetConditionals.h>
#include <stdbool.h>

extern void _swift_visit_EnvironmentKey(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_ViewTraitKey(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_View(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_ViewModifier(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_MultiView(void *_Nonnull content, void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_VISION

extern void _swift_visit_UIViewRepresentable(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_UIViewControllerRepresentable(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

#endif

#if TARGET_OS_OSX

extern void _swift_visit_NSViewRepresentable(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

extern void _swift_visit_NSViewControllerRepresentable(void *_Nonnull visitor, const void *_Nonnull type, const void *_Nonnull metadata, const void *_Nonnull conformance) __attribute__((swiftcall));

#endif

extern void *_Nullable swift_conformsToProtocol(const void *_Nonnull metadata, const void *_Nonnull descriptor);

void *_Nullable c_swift_conformsToProtocol(const void *_Nonnull metadata, const void *_Nonnull descriptor);

extern bool swift_isClassType(const void *_Nonnull metadata);

bool c_swift_isClassType(const void *_Nonnull metadata);

bool c_swift_isOpaqueTypeErasureEnabled();

#endif /* view_visitor_h */
