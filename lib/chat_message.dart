import 'package:flutter/material.dart';
import 'chat_user.dart';

@immutable
class ChatMessage implements Comparable {
  final ChatUser user;
  final Widget message;
  final DateTime sendDate;

  const ChatMessage({
    required this.user,
    required this.message,
    required this.sendDate,
  });

  @override
  int compareTo(other) {
    return sendDate.compareTo(other.sendDate);
  }
}