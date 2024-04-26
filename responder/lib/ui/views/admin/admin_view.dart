import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
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
          height: MediaQuery.of(context).size.height,
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
                height: screenHeight * 0.03,
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
                                Text(
                                  'Emergency History',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
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
                                                if (doc['userName'] != null &&
                                                    doc['situation'] != null &&
                                                    doc['phoneNum'] != null &&
                                                    doc['userConcern'] != null &&
                                                    doc['formattedDateAndTime'] != null) {
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
                                                        if (doc['userImage'] != null)
                                                          Image.network(
                                                            doc['userImage'],
                                                            width: 100,
                                                            height: 100,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        Text(
                                                          'User Name: ${doc['userName']}',
                                                          textAlign: TextAlign.start,
                                                        ),
                                                        Text(
                                                          'User Situation: ${doc['situation']}',
                                                          textAlign: TextAlign.start,
                                                        ),
                                                        if (doc['situationPhoto'] != null)
                                                          Image.network(
                                                            doc['situationPhoto'],
                                                            width: 100,
                                                            height: 100,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        Text(
                                                          'Phone Num: ${doc['phoneNum']}',
                                                          textAlign: TextAlign.start,
                                                        ),
                                                        Text(
                                                          'User Concern: ${doc['userConcern']}',
                                                          textAlign: TextAlign.start,
                                                        ),
                                                        Text(
                                                          'Formatted Date and Time: ${doc['formattedDateAndTime']}',
                                                          textAlign: TextAlign.start,
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                } else {
                                                  return Container();
                                                }
                                              },
                                            );
                                          } else {
                                            return const Text('No data available.');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
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
                        ],
                      ),
                    ),
DefaultTabController(
  length: 2, // Number of tabs
  child: Column(
    children: [
      TabBar(
        tabs: [
          Tab(text: 'Manage Requestors'), // Tab for managing requestors
          Tab(text: 'Manage Responders'), // Tab for managing responders
        ],
      ),
      Expanded(
        child: TabBarView(
          children: [
            // Tab view for managing requestors
            SingleChildScrollView(
        child: FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
          future: viewModel.fetchUsersCollection(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data![index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.white, // Add background color here
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container( // Wrap the contents in a Container widget
                            alignment: Alignment.centerLeft, // Justify the texts to the left
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display user image if available
                                if (doc.data()?['image'] != null)
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: NetworkImage(doc.data()?['image']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                    ),
                                  ),
                                // Display user name
                                Text(
                                  'Name: ${doc.data()?['name'] ?? 'No data available'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Email: ${doc.data()?['email'] ?? 'No data available'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                // Display user phone number
                                Text(
                                  'Phone Number: ${doc.data()?['phonenumber'] ?? 'No data available'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                // Display user situation
                                Text(
                                  'Situation: ${doc.data()?['situation'] ?? 'No data available'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                // Display user situation photo if available
                                if (doc.data()?['situationPhoto'] != null)
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: NetworkImage(doc.data()?['situationPhoto']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                    ),
                                  ),
                                // Display user concern
                                Text(
                                  'Concern: ${doc.data()?['concerns'] ?? 'No data available'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                // Display formatted date and time
                                Text(
                                  'Formatted Date and Time: ${doc.data()?['timestamp'] != null ? DateFormat.yMd().add_jm().format(doc.data()?['timestamp'].toDate()) : 'No data available'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Add edit and delete buttons
                        Column(
                          children: [
                            // Edit button
                            // Delete button
                            ElevatedButton(
                              onPressed: () async {
                                // Show confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("Confirm Delete"),
                                      content: Text("Are you sure you want to delete this user data?"),
                                      actions: <Widget>[
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            // Delete the data
                                            await viewModel.deleteUserData(doc.id); // Assuming doc.id is the document ID
                                            Navigator.of(context).pop(); // Close the dialog

                                            // Show a snackbar to indicate the data was deleted
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Data deleted successfully'))
                                            );

                                            // Refetch the user collection data to refresh the UI
                                            // This will trigger a rebuild of the UI
                                          },
                                          child: Text("Delete"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Icon(Icons.delete),
                            ),
                          ],
                        ),
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
      ),
 // Tab view for managing responders
           SingleChildScrollView(
  child: FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
    future: viewModel.fetchRespondersCollection(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data![index];
            return Container(
              margin: EdgeInsets.symmetric(vertical: 8.0),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white, // Add background color here
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (doc.data()?['image'] != null)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(8.0),
                                image: DecorationImage(
                                  image: NetworkImage(doc.data()?['image']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                width: 100,
                                height: 100,
                              ),
                            ),
                          Text(
                            'Name: ${doc.data()?['name'] ?? 'No data available'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Email: ${doc.data()?['email'] ?? 'No data available'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Phone Number: ${doc.data()?['phonenumber'] ?? 'No data available'}',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Concern: ${doc.data()?['concerns'] ?? 'No data available'}',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Formatted Date and Time: ${doc.data()?['timestamp'] != null ? DateFormat.yMd().add_jm().format(doc.data()?['timestamp'].toDate()) : 'No data available'}',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          // Show edit dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              String name = doc.data()?['name'] ?? '';
                              String email = doc.data()?['email'] ?? '';
                              String phoneNumber = doc.data()?['phonenumber'] ?? '';

                              return AlertDialog(
                                title: Text("Edit User"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      onChanged: (value) => name = value,
                                      decoration: InputDecoration(labelText: 'Name'),
                                      controller: TextEditingController(text: name),
                                    ),
                                    TextField(
                                      onChanged: (value) => email = value,
                                      decoration: InputDecoration(labelText: 'Email'),
                                      controller: TextEditingController(text: email),
                                    ),
                                    TextField(
                                      onChanged: (value) => phoneNumber = value,
                                      decoration: InputDecoration(labelText: 'Phone Number'),
                                      controller: TextEditingController(text: phoneNumber),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("Cancel"),
                                  ),
                                 ElevatedButton(
                                      onPressed: () async {
                                        // Save changes
                                        // Update the data with the new values
                                        await viewModel.updateUserData(
                                          doc.id, // Document ID
                                          {'name': name, 'email': email, 'phonenumber': phoneNumber},
                                        );
                                        Navigator.of(context).pop(); // Close the dialog

                                        // Show bottom sheet if successfully changed
                                        Scaffold.of(context).showBottomSheet((context) => Container(
                                          padding: EdgeInsets.all(16),
                                          child: Text('Data updated successfully'),
                                        ));
                                      },
                                      child: Text("Save"),
                                    ),


                                ],
                              );
                            },
                          );
                        },
                        child: Icon(Icons.edit),
                      ),
                      ElevatedButton(
                       onPressed: () async {
                       // Delete the data
                        await viewModel.deleteUserData(doc.id); // Assuming doc.id is the document ID
                          Navigator.of(context).pop(); // Close the dialog

                          // Show a snackbar to indicate the data was deleted
                            ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Data deleted successfully'))
                          );

                         // Refetch the user collection data to refresh the UI
                         // This will trigger a rebuild of the UI
                         },
                        child: Text("Delete"),
                        ),
                    ],
                  ),
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
),


          ],
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
                     const NavigationDestination(
                      icon: Icon(
                        Icons.account_circle,
                        size: 30,
                      ),
                      selectedIcon: Icon(
                        Icons.account_circle,
                        color: Color.fromARGB(255, 54, 244, 216),
                        size: 40,
                      ),
                      label: AppConstants.accountsText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
);

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
