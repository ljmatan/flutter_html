import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/src/anchor.dart';
import 'package:flutter_html/src/html_elements.dart';
import 'package:flutter_html/src/styled_element.dart';
import 'package:flutter_html/style.dart';
import 'package:html/dom.dart' as dom;

/// A [LayoutElement] is an element that breaks the normal Inline flow of
/// an html document with a more complex layout. LayoutElements handle
abstract class LayoutElement extends StyledElement {
  LayoutElement({
    String name = "[[No Name]]",
    required List<StyledElement> children,
    String? elementId,
    dom.Element? node,
  }) : super(
            name: name,
            children: children,
            style: Style(),
            node: node,
            elementId: elementId ?? "[[No ID]]");

  Widget? toWidget(RenderContext context);
}

class DetailsContentElement extends LayoutElement {
  List<dom.Element> elementList;

  DetailsContentElement({
    required String name,
    required List<StyledElement> children,
    required dom.Element node,
    required this.elementList,
  }) : super(name: name, node: node, children: children, elementId: node.id);

  @override
  Widget toWidget(RenderContext context) {
    List<InlineSpan>? childrenList =
        children.map((tree) => context.parser.parseTree(context, tree)).toList();
    List<InlineSpan> toRemove = [];
    for (InlineSpan child in childrenList) {
      if (child is TextSpan && child.text != null && child.text!.trim().isEmpty) {
        toRemove.add(child);
      }
    }
    for (InlineSpan child in toRemove) {
      childrenList.remove(child);
    }
    InlineSpan? firstChild = childrenList.isNotEmpty == true ? childrenList.first : null;
    return ExpansionTile(
        key: AnchorKey.of(context.parser.key, this),
        expandedAlignment: Alignment.centerLeft,
        title: elementList.isNotEmpty == true && elementList.first.localName == "summary"
            ? StyledText(
                textSpan: TextSpan(
                  style: style.generateTextStyle(),
                  children: firstChild == null ? [] : [firstChild],
                ),
                style: style,
                renderContext: context,
              )
            : Text("Details"),
        children: [
          StyledText(
            textSpan: TextSpan(
                style: style.generateTextStyle(),
                children: getChildren(
                    childrenList,
                    context,
                    elementList.isNotEmpty == true && elementList.first.localName == "summary"
                        ? firstChild
                        : null)),
            style: style,
            renderContext: context,
          ),
        ]);
  }

  List<InlineSpan> getChildren(
      List<InlineSpan> children, RenderContext context, InlineSpan? firstChild) {
    if (firstChild != null) children.removeAt(0);
    return children;
  }
}

class EmptyLayoutElement extends LayoutElement {
  EmptyLayoutElement({required String name}) : super(name: name, children: []);

  @override
  Widget? toWidget(_) => null;
}

LayoutElement parseLayoutElement(
  dom.Element element,
  List<StyledElement> children,
) {
  switch (element.localName) {
    case "details":
      if (children.isEmpty) {
        return EmptyLayoutElement(name: "empty");
      }
      return DetailsContentElement(
        node: element,
        name: element.localName!,
        children: children,
        elementList: element.children,
      );
    default:
      return EmptyLayoutElement(name: "empty");
  }
}
