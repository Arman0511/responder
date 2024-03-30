import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:responder/global/global_var.dart';
import 'package:responder/ui/custom_widget/app2_button.dart';
import 'package:responder/ui/custom_widget/app_body.dart';
import 'package:responder/ui/custom_widget/user_profile.dart';
import 'package:stacked/stacked.dart';
import 'package:responder/ui/common/ui_helpers.dart';

import '../../common/app_constants.dart';
import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    HomeViewModel viewModel,
    Widget? child,
  ) {
    double screenHeight = MediaQuery.of(context).size.height;

    return AppBody(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                primaryShadow(),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: viewModel.goToProfileView,
                  child: UserProfile(
                    name: viewModel.user.name,
                    imagePath: viewModel.user.image,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: screenHeight * 0.03, // Set height to 3% of screen height
          ),
          Expanded(
            child: PageView(
              controller: viewModel.pageController,
              onPageChanged: viewModel.onPageChanged,
              physics: NeverScrollableScrollPhysics(),
              children: [
                SingleChildScrollView(
                  child: Column(children: [
                    SizedBox(
                      height: screenHeight *
                          0.3, // Set height to 30% of screen height
                      child: GoogleMap(
                        mapType: MapType.normal,
                        myLocationEnabled: true,
                        initialCameraPosition: googlePlexInitialPosition,
                        onMapCreated: viewModel.mapCreated,
                      ),
                    ),
                  ]),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      ...List.generate(
                        10,
                        (index) => ElevatedButton(
                          onPressed: () {
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: index % 2 == 0 ? Colors.grey.shade200 : Colors.white,
                            padding: EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hi, how are you doing?',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '(12:01 PM)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: Colors.white,
              labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE35629),
                    );
                  } else {
                    return const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    );
                  }
                },
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.white,
              height: 70,
              shadowColor: Color(0xFF948D8D),
              selectedIndex: viewModel.currentPageIndex,
              onDestinationSelected: viewModel.onDestinationSelected,
              destinations: [
                NavigationDestination(
                  icon: Icon(
                    Icons.home,
                    size: 30,
                  ),
                  selectedIcon: Icon(
                    Icons.home,
                    color: const Color.fromARGB(255, 54, 244, 216),
                    size: 40,
                  ),
                  label: AppConstants.HomeText,
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.map,
                    size: 30,
                  ),
                  selectedIcon: Icon(
                    Icons.map,
                    color: const Color.fromARGB(255, 54, 244, 216),
                    size: 40,
                  ),
                  label: AppConstants.mapsText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      HomeViewModel(context);

  @override
  void onViewModelReady(HomeViewModel viewModel) {
    viewModel.init();
  }

}
