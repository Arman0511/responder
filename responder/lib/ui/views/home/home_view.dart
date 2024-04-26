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
          Text(
            'User Who Notified',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FutureBuilder<QuerySnapshot<Object?>>(
                    future: viewModel.fetchEmergencyHistory(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData &&
                          snapshot.data!.docs.isNotEmpty) {
                        var doc = snapshot.data!
                            .docs[0]; // Get the first (most recent) document
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.white, // Add a background color
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3), // Add a drop shadow
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Center the contents
                              children: [
                                // Display image if available
                                if (doc['userImage'] != null)
                                  GestureDetector(
                                    onTap: () {
                                      // Show dialog box with full-size image
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            child:
                                                Image.network(doc['userImage']),
                                          );
                                        },
                                      );
                                    },
                                    child: Image.network(
                                      doc['userImage'],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                SizedBox(height: 16.0), // Add some spacing
                                Text('User Name: ${doc['userName']}'),
                                SizedBox(height: 8.0), // Add some spacing
                                Text('Phone Num: ${doc['phoneNum']}'),
                                SizedBox(height: 8.0), // Add some spacing
                                Text('User Concern: ${doc['userConcern']}'),
                                SizedBox(height: 8.0), // Add some spacing
                                Text(
                                    'Formatted Date and Time: ${doc['formattedDateAndTime']}'),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Text('No data available.');
                      }
                    },
                  ),
                  SizedBox(
                    height: 20.0, // Add spacing between the box and the button
                  ),
                  Tooltip(
                    message:
                        'Click this button if you arrived at the destination',
                   child: Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => viewModel.sendNotificationAdmin(context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: Text('Arrived'),
                      ),
                    ),

                  ),
                  SizedBox(
                    height:
                        16.0, // Add some spacing between the button and the description
                  ),
                  Text(
                    'Click this button if you arrived at the destination',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      textBaseline: TextBaseline.alphabetic,
                      fontStyle: FontStyle.normal, // Italicize the text
                      color: Colors
                          .black54, // Change the text color to a darker shade of grey
                      fontSize: 20, // Increase the font size
                    ),
                  ),
                ],
              ),
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
