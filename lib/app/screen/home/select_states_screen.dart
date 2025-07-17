import 'dart:convert';

import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/service/location_service.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:flutter/material.dart';

class SelectStatesScreen extends StatefulWidget {
  const SelectStatesScreen({super.key});

  @override
  State<SelectStatesScreen> createState() => _SelectStatesScreenState();
}

class _SelectStatesScreenState extends State<SelectStatesScreen> {
  // future to load the states for India
  late Future _loadStates;

  // list of selected states
  final List selectedStates = getPrefValue(Keys.PREFERRED_STATES).isEmpty
      ? []
      : jsonDecode(getPrefValue(Keys.PREFERRED_STATES));

  @override
  void initState() {
    super.initState();

    _loadStates = LocationService.getState("1-India");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        elevation: 0,
        title: 'Select States',
        leadingBack: true,
        trailling: const SizedBox(),
      ),
      body: FutureBuilder(
        future: _loadStates,
        builder: ((context, snapshot) {
          // if loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          // if there is an error
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong!'),
            );
          }

          // grabbing the data
          final List<LocationModel> states = snapshot.data;

          // sorting the data
          states.sort((a, b) => a.name.compareTo(b.name));

          return Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'We will only show you posts from the selected states in the Home tab.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...states.map(
                        (state) {
                          bool isCurrentLocationState = state.name ==
                              locationModelFromJson(getPrefValue(Keys.STATE))
                                  .name;

                          return CheckboxListTile(
                            value: isCurrentLocationState
                                ? true
                                : selectedStates.any((selectedState) =>
                                    selectedState.toLowerCase() ==
                                    state.name.toLowerCase()),
                            onChanged: (value) {
                              // if is current location state, skip it
                              if (isCurrentLocationState) {
                                return;
                              }

                              // if true, add the current state name in the list, otherwise remove it
                              if (value!) {
                                setState(() {
                                  selectedStates.add(state.name);
                                });
                              } else {
                                setState(() {
                                  selectedStates.remove(state.name);
                                });
                              }
                            },
                            title: Text(state.name),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // if no items are selected, we deny the save
                          if (selectedStates.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Please select at least one state!'),
                              ),
                            );
                            return;
                          }

                          // if more than 5 are selected, we deny again
                          if (selectedStates.length > 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Please select at most five states!'),
                              ),
                            );
                            return;
                          }

                          // setting the list in the shared pref
                          setPrefValue(Keys.PREFERRED_STATES,
                              jsonEncode(selectedStates));

                          // popping the page
                          Navigator.of(context).pop(true);
                        },
                        child: Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
