import 'package:chunaw/app/widgets/app_button.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms and Conditions'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I fully understand that Pradhaan is a social media application which provides user freedom to express his observation and view. Thus, the person expressing his view is the one responsible for comments, views, opinions expressed by him or her.\n\nI agree to follow highest level of morality, integrity while using Pradhaan. And that my actions would in no way will go against the law of the land i.e India laws at the time\n\nI agree to respect other\'s Privacy, resist from spreading fake news, and would not post anything that hampers National Security, Public order and Public morality.',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            buttonText: 'I agree',
          ),
        ],
      ),
    );
  }
}
