//
// Copyright (c) Nathan Tannar
//

#include "visitors.h"

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

#if TARGET_OS_IOS || TARGET_OS_TV

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
#if TARGET_OS_IOS || TARGET_OS_TV
    if (descriptor == _UIViewRepresentableProtocolDescriptor())
    {
        _swift_visit_UIViewRepresentable(visitor, metadata, metadata, conformance);
    }
    if (descriptor == _UIViewControllerRepresentableProtocolDescriptor())
    {
        _swift_visit_UIViewControllerRepresentable(visitor, metadata, metadata, conformance);
    }
#endif
#if TARGET_OS_OSX
    if (descriptor == _NSViewRepresentableProtocolDescriptor())
    {
        _swift_visit_NSViewRepresentable(visitor, metadata, metadata, conformance);
    }
    if (descriptor == _NSViewControllerRepresentableProtocolDescriptor())
    {
        _swift_visit_NSViewControllerRepresentable(visitor, metadata, metadata, conformance);
    }
#endif
    _swift_visit_View(visitor, metadata, metadata, conformance);
}

void c_visit_ViewModifier(void *_Nonnull visitor, const void *_Nonnull metadata, const void *_Nonnull conformance)
{
    _swift_visit_ViewModifier(visitor, metadata, metadata, conformance);
}


void c_visit_MultiView(void *_Nonnull content, void *_Nonnull visitor, const void *_Nonnull metadata, const void *_Nonnull conformance)
{
    _swift_visit_MultiView(content, visitor, metadata, metadata, conformance);
}
