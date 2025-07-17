import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingDialog extends StatefulWidget {
  static bool isCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Start of the week (Monday)
    final endOfWeek = startOfWeek.add(Duration(days: 6)); // End of the week (Sunday)
    print("ishwar:time startOfWeek: $startOfWeek");
    return (DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).isAtSameMomentAs(DateTime(date.year, date.month, date.day)) || date.isAfter(startOfWeek)) && date.isBefore(endOfWeek.add(Duration(days: 1)));
  }
  
  static Future<bool> openMeetingDialog(BuildContext context, String scope) async {

    final meetingData = (await FirebaseFirestore.instance.collection('meetings').doc(scope).get()).data();
    print("ishwar:time meeting data: $meetingData");

    if (meetingData != null && isCurrentWeek((meetingData['created_at'] ?? Timestamp.fromDate(DateTime(2001))).toDate())) {
      return true;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MeetingDialog(scope: scope),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting added successfully!')),
      );
    }

    return result == true;
  }

  final String scope; // Pass the scope dynamically

  const MeetingDialog({Key? key, required this.scope}) : super(key: key);

  @override
  State<MeetingDialog> createState() => _MeetingDialogState();
}

class _MeetingDialogState extends State<MeetingDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDateTime;
  bool _isLoading = false;

  Future<void> _pickDateTime() async {
    DateTime now = DateTime.now();
    DateTime endOfWeek = now.copyWith(hour: 0, minute: 0);
    endOfWeek = endOfWeek.add(Duration(days: 7 - endOfWeek.weekday));
    print("ishwar: ${endOfWeek}");
    // Pick Date
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: endOfWeek,
    );

    if (date == null) return;

    // Pick Time
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate() && _selectedDateTime != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Push data to Firestore
        await FirebaseFirestore.instance.collection('meetings').doc(widget.scope).set({
          'meeting_time': _selectedDateTime!,
          'address': _addressController.text,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Pop with success result
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        // Handle Firestore errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add meeting: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meeting time.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Schedule Meeting',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Meeting Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDateTime != null
                        ? '${_selectedDateTime!.toLocal()}'.split('.')[0]
                        : 'Select Date & Time',
                    style: TextStyle(
                      color: _selectedDateTime != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLength: 60 - 22,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter meeting address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  if (value.length < 10) {
                    return 'Address should be at least 10 characters long';
                  }
                  final addressRegex = RegExp(r'^[a-zA-Z0-9\s,.-]+$');
                  if (!addressRegex.hasMatch(value)) {
                    return 'Address contains invalid characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _submitData,
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
