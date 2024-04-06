import 'package:flutter/material.dart';
import 'package:responder/ui/constants/app_png.dart';
import 'package:responder/ui/custom_widget/app2_button.dart';
import 'package:responder/ui/custom_widget/app_body.dart';
import 'package:responder/ui/custom_widget/app_button.dart';
import 'package:responder/ui/custom_widget/app_image.dart';
import 'package:responder/ui/custom_widget/app_password_textfield.dart';
import 'package:responder/ui/custom_widget/app_textbutton.dart';
import 'package:responder/ui/custom_widget/app_textfield.dart';
import 'package:responder/ui/custom_widget/app_title_text.dart';
import 'package:stacked/stacked.dart';

import '../../common/app_constants.dart';
import 'login_viewmodel.dart';

class LoginView extends StackedView<LoginViewModel> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    LoginViewModel viewModel,
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
                  const AppTitleText(text: AppConstants.welcomeText),
                  const SizedBox(
                    height: 10,
                  ),
                  const AppImage(path: AppPng.AppAuthLoginPath),
                  const SizedBox(
                    height: 25,
                  ),
                  AppTextField(
                    controller: viewModel.emailController,
                    label: AppConstants.emailText,
                  ),
                  AppPasswordTextField(
                    controller: viewModel.passwordController,
                    label: AppConstants.passwordText,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  AppButton(
                    text: AppConstants.loginText,
                    onClick: viewModel.logIn,
                    isSelected: false,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  AppTextButton(
                    title: AppConstants.createNewAccText,
                    onClick: viewModel.goToSignUp,
                  ),
                  AppTextButton(
                    title: AppConstants.forgotPassText,
                    onClick: viewModel.goToForgotPassword,
                  ),
                  ElevatedButton(
                    onPressed: viewModel.showadminLoginDialog,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: Colors.black,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      shadowColor: Colors.grey,
                    ),
                    child: const Text(
                      "Login as Admin",
                      style: TextStyle(
                        color: Colors.black,
                        letterSpacing: 1,
                        wordSpacing: 2,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  LoginViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      LoginViewModel();
}
