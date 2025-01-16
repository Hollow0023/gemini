import 'package:flutter/material.dart';

@immutable
class ChatUser {
  final String name;
  final Color color;
  final Color messageColor;
  final Color messageBackgroundColor;
  final Icon? icon;

  const ChatUser({
    required this.name,
    required this.color,
    required this.messageColor,
    required this.messageBackgroundColor,
    this.icon,

  });
}