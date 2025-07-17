import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/location_model.dart';
import '../service/location_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/app_drop_down.dart';

class LevelSelectorSheet extends StatefulWidget {
  static void show(BuildContext context, Function(LocationModel? state, LocationModel? city, LocationModel? postal) onFilter,
      {LocationModel? defaultState, LocationModel? defaultCity, LocationModel? defaultPostal, bool? hidePostal, bool? allField}) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return LevelSelectorSheet(
          onFilter,
          defaultState: defaultState,
          defaultCity: defaultCity,
          defaultPostal: defaultPostal,
          hidePostal: hidePostal ?? false,
          allField: allField ?? false,
        );
      },
    );
  }

  final Function(LocationModel? state, LocationModel? city, LocationModel? postal) onFilter;
  final LocationModel? defaultState;
  final LocationModel? defaultCity;
  final LocationModel? defaultPostal;
  final bool hidePostal;
  final bool allField;

  const LevelSelectorSheet(this.onFilter,
      {super.key, this.defaultState, this.defaultCity, this.defaultPostal, this.hidePostal = false, this.allField = false});

  @override
  State<StatefulWidget> createState() => _LevelSelectorState();
}

class _LevelSelectorState extends State<LevelSelectorSheet> {
  LocationModel? selectedState;
  LocationModel? selectedCity;
  LocationModel? selectedPostal;

  List<LocationModel> states = [];
  List<LocationModel> cities = [];
  List<LocationModel> postals = [];

  bool isStatesLoading = false;
  bool isCitiesLoading = false;
  bool isPostalsLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchStates();
    if (widget.defaultState != null) {
      await _fetchCities(widget.defaultState!.id);
      if (widget.defaultCity != null) {
        await _fetchPostals(widget.defaultState!.id, widget.defaultCity!.id);
      }
    }

    selectedState = widget.defaultState;
    selectedCity = widget.defaultCity;
    selectedPostal = widget.defaultPostal;
  }

  Future<void> _fetchStates() async {
    setState(() => isStatesLoading = true);
    try {
      states = await LocationService.getState("1-India");
      states.sort((a, b) => a.name.compareTo(b.name));
    } finally {
      setState(() => isStatesLoading = false);
    }
  }

  Future<void> _fetchCities(String stateId) async {
    setState(() {
      isCitiesLoading = true;
      cities = [];
      postals = [];
      selectedCity = null;
      selectedPostal = null;
    });

    try {
      cities = await LocationService.getCity("1-India", stateId);
      cities.sort((a, b) => a.name.compareTo(b.name));
    } finally {
      setState(() => isCitiesLoading = false);
    }
  }

  Future<void> _fetchPostals(String stateId, String cityId) async {
    setState(() {
      isPostalsLoading = true;
      postals = [];
      selectedPostal = null;
    });

    try {
      postals = await LocationService.getPostal("1-India", stateId, cityId);
      postals.sort((a, b) => a.name.compareTo(b.name));
    } finally {
      setState(() => isPostalsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStateSelector(),
            _buildCitySelector(),
            if (!widget.hidePostal) _buildPostalSelector(),
            const SizedBox(height: 8.0),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSelector() {
    return _buildSelector(
      hint: 'Select State',
      items: states,
      isLoading: isStatesLoading,
      selectedItem: selectedState,
      onChanged: (state) {
        setState(() {
          selectedState = state;
          selectedCity = null;
          selectedPostal = null;
          cities = [];
          postals = [];
        });
        if (state != null) _fetchCities(state.id);
      },
      onClear: () {
        setState(() {
          selectedState = null;
          selectedCity = null;
          selectedPostal = null;
          cities = [];
          postals = [];
        });
      },
    );
  }

  Widget _buildCitySelector() {
    return _buildSelector(
      hint: 'Select City',
      items: cities,
      isLoading: isCitiesLoading,
      selectedItem: selectedCity,
      onChanged: (city) {
        setState(() {
          selectedCity = city;
          selectedPostal = null;
          postals = [];
        });
        if (city != null && !widget.hidePostal) {
          _fetchPostals(selectedState!.id, city.id);
        }
      },
      onClear: () {
        setState(() {
          selectedCity = null;
          selectedPostal = null;
          postals = [];
        });
      },
    );
  }

  Widget _buildPostalSelector() {
    return _buildSelector(
      hint: 'Select Postal',
      items: postals,
      isLoading: isPostalsLoading,
      selectedItem: selectedPostal,
      onChanged: (postal) => setState(() => selectedPostal = postal),
      onClear: () => setState(() => selectedPostal = null),
    );
  }

  Widget _buildSelector({
    required String hint,
    required List<LocationModel> items,
    required bool isLoading,
    required LocationModel? selectedItem,
    required Function(LocationModel?) onChanged,
    required Function() onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: isLoading
          ? _buildShimmer()
          : AppDropDown(
        hint: hint,
        hintWidget: selectedItem == null ? null : Text(
            selectedItem.name,
          style: TextStyle(
              fontFamily: AppFonts.Montserrat,
              color: selectedItem.id == ""
                  ? Colors.black.withOpacity(0.51)
                  : AppColors.black,
              fontSize: 14
          ),
        ),
        showClearButton: selectedItem != null,
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item.name),
        )).toList(),
        onChanged: (value) => onChanged(value),
        onClear: onClear,
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.baseColor,
      ),
    ).animate(onComplete: (controller) => controller.repeat()).shimmer(delay: 500.ms, duration: 800.ms);
  }

  Widget _buildApplyButton() {
    return ElevatedButton(
      style: ButtonStyle(
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 15)),
      ),
      onPressed: () {
        if (widget.allField) {
          final hasMissingFields = selectedCity == null || selectedState == null || (!widget.hidePostal && selectedPostal == null);
          if (hasMissingFields) {
            longToastMessage('Please select all fields');
            return;
          }
        }
        widget.onFilter(selectedState, selectedCity, selectedPostal);
        Navigator.pop(context);
      },
      child: const Text('Apply Filter'),
    );
  }
}