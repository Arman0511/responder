import 'package:flutter/material.dart';
import 'package:responder/ui/common/app_constants.dart';
import 'package:responder/ui/constants/app_png.dart';
import 'package:responder/ui/custom_widget/app2_button.dart';
import 'package:responder/ui/custom_widget/app_body.dart';
import 'package:responder/ui/custom_widget/app_image.dart';
import 'package:responder/ui/custom_widget/app_textfield.dart';
import 'package:responder/ui/custom_widget/app_title_text.dart';
import 'package:stacked/stacked.dart';

import 'forgot_password_view_viewmodel.dart';

class ForgotPasswordViewView extends StackedView<ForgotPasswordViewViewModel> {
  const ForgotPasswordViewView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    ForgotPasswordViewViewModel viewModel,
    Widget? child,
  ) {
    return AppBody(
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppBar(),
            AppTitleText(text: AppConstants.forgotPassText),
            AppImage(path: AppPng.AppAuthForgotPath),
            SizedBox(
              height: 25,
            ),
            AppTextField(
              controller: viewModel.emailController,
              label: AppConstants.emailText,
            ),
            App2Button(
              text: AppConstants.sentResetPassLinkText,
              onClick: () {},
              isSelected: false,
            ),
          ],
        ),
      ),
    );
  }

  @override
  ForgotPasswordViewViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      ForgotPasswordViewViewModel();
}
