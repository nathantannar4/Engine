//
// Copyright (c) Nathan Tannar
//

#include "visitors.h"
#include <AvailabilityMacros.h>

extern char $s7SwiftUI14EnvironmentKeyMp;

const void *_EnvironmentKeyProtocolDescriptor(void) {
    return &$s7SwiftUI14EnvironmentKeyMp;
}

extern char $s7SwiftUI13_ViewTraitKeyMp;

const void *_ViewTraitKeyProtocolDescriptor(void) {
    return &$s7SwiftUI13_ViewTraitKeyMp;
}

extern char $s7SwiftUI4ViewMp;

const void *_ViewProtocolDescriptor(void) {
    return &$s7SwiftUI4ViewMp;
}

extern char $s7SwiftUI12ViewModifierMp;

const void *_ViewModifierProtocolDescriptor(void) {
    return &$s7SwiftUI12ViewModifierMp;
}

extern char $s10EngineCore9MultiViewMp;

const void *_MultiViewProtocolDescriptor(void) {
    return &$s10EngineCore9MultiViewMp;
}

#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_VISION

extern char $s7SwiftUI19UIViewRepresentableMp;

const void *_UIViewRepresentableProtocolDescriptor(void) {
    return &$s7SwiftUI19UIViewRepresentableMp;
}

extern char $s7SwiftUI29UIViewControllerRepresentableMp;

const void *_UIViewControllerRepresentableProtocolDescriptor(void) {
    return &$s7SwiftUI29UIViewControllerRepresentableMp;
}

#endif

#if TARGET_OS_OSX

extern char $s7SwiftUI19NSViewRepresentableMp;

const void *_NSViewRepresentableProtocolDescriptor(void) {
    return &$s7SwiftUI19NSViewRepresentableMp;
}

extern char $s7SwiftUI29NSViewControllerRepresentableMp;

const void *_NSViewControllerRepresentableProtocolDescriptor(void) {
    return &$s7SwiftUI29NSViewControllerRepresentableMp;
}

#endif

void c_visit_EnvironmentKey(void *_Nonnull visitor, const void *_Nonnull metadata, const void *_Nonnull conformance)
{
    _swift_visit_EnvironmentKey(visitor, metadata, metadata, conformance);
}

void c_visit_ViewTraitKey(void *_Nonnull visitor, const void *_Nonnull metadata, const void *_Nonnull conformance)
{
    _swift_visit_ViewTraitKey(visitor, metadata, metadata, conformance);
}

void c_visit_View(void *_Nonnull visitor, const void *_Nonnull metadata, const void *_Nonnull conformance, const void *_Nonnull descriptor)
{
#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_VISION
    if (descriptor == _UIViewRepresentableProtocolDescriptor())
    {
        _swift_visit_UIViewRepresentable(visitor, metadata, metadata, conformance);
    }
    else if (descriptor == _UIViewControllerRepresentableProtocolDescriptor())
    {
        _swift_visit_UIViewControllerRepresentable(visitor, metadata, metadata, conformance);
    }
    else
    {
        _swift_visit_View(visitor, metadata, metadata, conformance);
    }
#elif TARGET_OS_OSX
    if (descriptor == _NSViewRepresentableProtocolDescriptor())
    {
        _swift_visit_NSViewRepresentable(visitor, metadata, metadata, conformance);
    }
    else if (descriptor == _NSViewControllerRepresentableProtocolDescriptor())
    {
        _swift_visit_NSViewControllerRepresentable(visitor, metadata, metadata, conformance);
    }
    else
    {
        _swift_visit_View(visitor, metadata, metadata, conformance);
    }
#else
    _swift_visit_View(visitor, metadata, metadata, conformance);
#endif
}

void c_visit_ViewModifier(void *_Nonnull visitor, const void *_Nonnull metadata, const void *_Nonnull conformance)
{
    _swift_visit_ViewModifier(visitor, metadata, metadata, conformance);
}


void c_visit_MultiView(void *_Nonnull content, void *_Nonnull visitor, const void *_Nonnull metadata, const void *_Nonnull conformance)
{
    _swift_visit_MultiView(content, visitor, metadata, metadata, conformance);
}

void *_Nullable c_swift_conformsToProtocol(const void *_Nonnull metadata, const void *_Nonnull descriptor)
{
    void *conformance = swift_conformsToProtocol(metadata, descriptor);
    return conformance;
}

bool c_swift_isClassType(const void *_Nonnull metadata)
{
    bool isClass = swift_isClassType(metadata);
    return isClass;
}

bool c_swift_isOpaqueTypeErasureEnabled()
{
    #if defined(__IPHONE_OS_VERSION_MAX_ALLOWED)
    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_18_4
    return false;
    #elif __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_18_0
    return true;
    #else
    return false;
    #endif

    #elif defined(__WATCH_OS_VERSION_MAX_ALLOWED)
    #if __WATCH_OS_VERSION_MAX_ALLOWED >= __WATCHOS_11_4
    return false;
    #elif __WATCH_OS_VERSION_MAX_ALLOWED >= __WATCHOS_11_0
    return true;
    #else
    return false;
    #endif

    #elif defined(__TV_OS_VERSION_MAX_ALLOWED)
    #if __TV_OS_VERSION_MAX_ALLOWED >= __TVOS_18_4
    return false;
    #elif __TV_OS_VERSION_MAX_ALLOWED >= __TVOS_18_0
    return true;
    #else
    return false;
    #endif

    #elif defined(__VISION_OS_VERSION_MAX_ALLOWED)
    #if __VISION_OS_VERSION_MAX_ALLOWED >= __VISIONOS_2_4
    return false;
    #elif __VISION_OS_VERSION_MAX_ALLOWED >= __VISIONOS_2_0
    return true;
    #else
    return false;
    #endif

    #elif defined(__MAC_OS_X_VERSION_MAX_ALLOWED)
    #if __MAC_OS_X_VERSION_MAX_ALLOWED >= __MAC_15_4
    return false;
    #elif __MAC_OS_X_VERSION_MAX_ALLOWED >= __MAC_15_0
    return true;
    #else
    return false;
    #endif

    #else
    return false;
    #endif
}
