import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:responder/global/global_var.dart';
import 'package:responder/ui/common/app_constants.dart';
import 'package:responder/ui/common/ui_helpers.dart';
import 'package:responder/ui/custom_widget/app_body.dart';
import 'package:responder/ui/custom_widget/user_profile.dart';
import 'package:stacked/stacked.dart';

import 'admin_viewmodel.dart';

class AdminView extends StackedView<AdminViewModel> {
  const AdminView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    AdminViewModel viewModel,
    Widget? child,
  ) {
    double screenHeight = MediaQuery.of(context).size.height;

    return AppBody(
        body: viewModel.isBusy
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SizedBox(
          height: MediaQuery.of(context).size.height, // or any fixed height you desire
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                        name: viewModel.admin.name,
                        imagePath: viewModel.admin.image,
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
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SingleChildScrollView(
                        child: Column(
                          children: [
                            // Your existing widgets
                            FutureBuilder<QuerySnapshot<Object?>>(
                              future: viewModel.fetchEmergencyHistory(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: snapshot.data!.docs.length,
                                    itemBuilder: (context, index) {
                                      var doc = snapshot.data!.docs[index];
                                      return Container(
                                        margin: EdgeInsets.symmetric(vertical: 8.0),
                                        padding: EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Display image if available
                                            if (doc['userImage'] != null)
                                              Image.network(
                                                doc['userImage'],
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            Text('User Name: ${doc['userName']}'),
                                            Text('Phone Num: ${doc['phoneNum']}'),
                                            Text('User Concern: ${doc['userConcern']}'),
                                            Text('Formatted Date and Time: ${doc['formattedDateAndTime']}'),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  return const Text('No data available.');
                                }
                              },
                            ),
                            // Your other widgets
                          ],
                        ),
                      ),
                  SingleChildScrollView(
                      child: Column(
                        children: [
                         Container(
                                height: 400, // Set a specific height for the GoogleMap
                                child: GoogleMap(
                                  markers: viewModel.markers.values.toSet(),
                                  mapType: MapType.normal,
                                  myLocationEnabled: true,
                                  initialCameraPosition: googlePlexInitialPosition,
                                  onMapCreated: viewModel.mapCreated,
                                ),
                              ),
                          SizedBox(height: 20), // Add some spacing between the map and the button
                          ElevatedButton(
                            onPressed:viewModel.showNearestResponder,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50), // Set width to match parent and height to 50
                            ),
                            child: Text('Show the nearest responder', style: TextStyle(fontSize: 18)), // You can adjust the font size as well
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed:viewModel.markNearestResponder,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50), // Set width to match parent and height to 50
                            ),
                            child: Text('Mark the nearest Responder', style: TextStyle(fontSize: 18)), // You can adjust the font size as well
                          ),
                        ],
                      ),
                    ),

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
                  shadowColor: const Color(0xFF948D8D),
                  selectedIndex: viewModel.currentPageIndex,
                  onDestinationSelected: viewModel.onDestinationSelected,
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(
                        Icons.home,
                        size: 30,
                      ),
                      selectedIcon: Icon(
                        Icons.home,
                        color: Color.fromARGB(255, 54, 244, 216),
                        size: 40,
                      ),
                      label: AppConstants.HomeText,
                    ),
                    const NavigationDestination(
                      icon: Icon(
                        Icons.map,
                        size: 30,
                      ),
                      selectedIcon: Icon(
                        Icons.map,
                        color: Color.fromARGB(255, 54, 244, 216),
                        size: 40,
                      ),
                      label: AppConstants.mapsText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  @override
  AdminViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      AdminViewModel(context);

  @override
  void onViewModelReady(AdminViewModel viewModel) {
    viewModel.init();
  }
}
