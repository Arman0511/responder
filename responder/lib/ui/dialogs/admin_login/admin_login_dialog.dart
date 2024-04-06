import 'package:flutter/material.dart';
import 'package:responder/ui/common/app_colors.dart';
import 'package:responder/ui/common/ui_helpers.dart';
import 'package:responder/ui/custom_widget/app_button.dart';
import 'package:responder/ui/custom_widget/app_loading.dart';
import 'package:responder/ui/custom_widget/app_password_textfield.dart';
import 'package:responder/ui/custom_widget/app_textfield.dart';
import 'package:responder/ui/custom_widget/dialog_bar.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import 'admin_login_dialog_model.dart';

const double _graphicSize = 60;

class AdminLoginDialog extends StackedView<AdminLoginDialogModel> {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  const AdminLoginDialog({
    Key? key,
    required this.request,
    required this.completer,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    AdminLoginDialogModel viewModel,
    Widget? child,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.white,
      child: viewModel.isBusy
          ? const AppLoading()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogBar(
                  onClick: () => completer(DialogResponse(confirmed: true)),
                  title: "Admin Login",
                ),
                verticalSpaceMedium,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      AppTextField(
                          controller: viewModel.emailTextController,
                          label: "User Name"),
                      AppPasswordTextField(
                          controller: viewModel.passwordTextController,
                          label: " Password"),
                    ],
                  ),
                ),
                AppButton(
                  text: "Login",
                  onClick: viewModel.logIn,
                  isSelected: false,
                ),
                verticalSpaceMedium,
              ],
            ),
    );
  }

  @override
  AdminLoginDialogModel viewModelBuilder(BuildContext context) =>
      AdminLoginDialogModel();
}
