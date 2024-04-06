import 'package:flutter/material.dart';
import 'package:responder/ui/common/app_constants.dart';
import 'package:responder/ui/constants/app_png.dart';
import 'package:responder/ui/custom_widget/app2_button.dart';
import 'package:responder/ui/custom_widget/app_body.dart';
import 'package:responder/ui/custom_widget/app_image.dart';
import 'package:responder/ui/custom_widget/app_password_textfield.dart';
import 'package:responder/ui/custom_widget/app_textfield.dart';
import 'package:responder/ui/custom_widget/app_title_text.dart';
import 'package:stacked/stacked.dart';

import 'admin_signup_viewmodel.dart';

class AdminSignupView extends StackedView<AdminSignupViewModel> {
  const AdminSignupView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    AdminSignupViewModel viewModel,
    Widget? child,
  ) {
    return AppBody(
        body: SingleChildScrollView(
      child: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                AppBar(),
                AppTitleText(text: AppConstants.createAccText),
                AppImage(path: AppPng.AppAuthCreatePath),
                SizedBox(
                  height: 25,
                ),
                SizedBox(
                  height: 25,
                ),
                AppTextField(
                  controller: viewModel.nameTextController,
                  label: AppConstants.nameText,
                  icon: Icon(
                    Icons.person,
                    color: const Color.fromARGB(255, 32, 211, 217),
                  ),
                ),
                AppTextField(
                  controller: viewModel.phoneNumTextController,
                  label: AppConstants.phoneNumText,
                  icon: Icon(
                    Icons.contact_phone,
                    color: const Color.fromARGB(255, 32, 211, 217),
                  ),
                ),
                AppTextField(
                    controller: viewModel.emailTextController,
                    label: AppConstants.emailText),
                AppPasswordTextField(
                  controller: viewModel.passwordTextController,
                  label: AppConstants.passwordText,
                ),
                App2Button(
                  text: AppConstants.createText,
                  onClick: viewModel.signupPressed,
                  isSelected: false,
                )
              ],
            ),
    ));
  }

  @override
  AdminSignupViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      AdminSignupViewModel();
}
