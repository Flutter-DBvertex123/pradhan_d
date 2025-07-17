import 'dart:convert';

import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/show_snack_bar.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

enum PollStatus { active, inactive }

class CreatePollPage extends StatefulWidget {
  const CreatePollPage({
    super.key,
    required this.level,
  });

  final int level;

  @override
  State<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final questionController = TextEditingController();
  final optionsControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  bool creatingPoll = false;

  // form key
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Poll'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      CustomTextField(
                        controller: questionController,
                        minLines: 2,
                        maxLines: 2,
                        hintText: 'Question',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Question can not be empty';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        'Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ...optionsControllers.asMap().keys.map((index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CustomTextField(
                            controller: optionsControllers[index],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Option ${index + 1} can not be empty';
                              }

                              return null;
                            },
                            label: Text('Option ${index + 1}'),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
            AppButton(
              buttonText: creatingPoll ? 'Adding ...' : 'Add Poll',
              onPressed: () async {
                _handleFormSubmission();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFormSubmission() async {
    // if adding already, ignore
    if (creatingPoll) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        creatingPoll = true;
      });

      // adding a poll
      final doc = FirebaseFirestore.instance.collection('polls').doc();

      await doc.set({
        'city': widget.level <= 2
            ? _getIdFromLocationModelOf(getPrefValue(Keys.CITY))
            : '',
        'country': widget.level <= 4
            ? _getIdFromLocationModelOf(getPrefValue(Keys.COUNTRY))
            : '',
        'postal': widget.level == 1
            ? _getIdFromLocationModelOf(getPrefValue(Keys.POSTAL))
            : '',
        'state': widget.level <= 3
            ? _getIdFromLocationModelOf(getPrefValue(Keys.STATE))
            : '',
        'status': 'active',
        'created_by': getPrefValue(Keys.USERID),
        'created_at': DateTime.now(),
        'poll_id': doc.id,
        'question': questionController.text.trim(),
        'options': optionsControllers.map((optionController) {
          return {
            'count': 0,
            'id': Uuid().v4(),
            'text': optionController.text,
          };
        }).toList()
      });

      if (context.mounted) {
        Get.back();
        showSnackBar(context, message: 'Poll has been added!');
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, message: e.toString());
      }
    } finally {
      setState(() {
        creatingPoll = false;
      });
    }
  }

  String _getIdFromLocationModelOf(String prefValue) {
    return LocationModel.fromJson(jsonDecode(prefValue)).id;
  }
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.label,
    this.controller,
    this.minLines,
    this.maxLines,
    this.hintText,
    this.validator,
  });

  final Widget? label;
  final TextEditingController? controller;
  final int? minLines;
  final int? maxLines;
  final String? hintText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        label: label,
        isDense: true,
        hintText: hintText,
        hintStyle: TextStyle(fontWeight: FontWeight.normal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}
