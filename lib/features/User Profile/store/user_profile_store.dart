import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:mess_mgmt/Global/models/coupon_data_model.dart';
import 'package:mess_mgmt/Global/store/app_state_store.dart';
import 'package:mess_mgmt/features/User%20Profile/repository/user_profile_repo.dart';
import 'package:mess_mgmt/features/auth/error%20handling/auth_error.dart';
import 'package:mess_mgmt/features/dashboard/stores/dashboard_store.dart';
import 'package:mobx/mobx.dart';

part 'user_profile_store.g.dart';

final userProfileStore = UserProfileStore();

class UserProfileStore = UserProfile with _$UserProfileStore;

abstract class UserProfile with Store {
  @observable
  ObservableList<CouponDataModel> userSellingCouponsList =
      ObservableList<CouponDataModel>();

  @observable
  bool isLoading = false;

  @observable
  bool isLoadingLocally = false;

    
  @observable
  bool isCouponLoaded = true;

  @action
  Future fetchSellingCouponList() async {
    isLoading = true;
    try {
      final response = await UserProfileRepo.getUserCouponList();

      final jsonList = jsonDecode(response.body)['data'];
      if (response.statusCode == 200) {
        isCouponLoaded = true;
        List<CouponDataModel> list = [];
        for (final doc in jsonList) {
          list.add(CouponDataModel.fromJson(doc));
        }
        userSellingCouponsList = ObservableList.of(list);
      } else {
        isCouponLoaded = false;
        appState.authError = const AuthErrorUnknownIssue();
      }
    } on SocketException {
      appState.authError = const AuthErrorNetworkIssue();
      isCouponLoaded = false;
    } on ClientException {
      isCouponLoaded = false;
      appState.authError = const AuthErrorNetworkIssue();
    } on TimeoutException {
      isCouponLoaded = false;
      appState.authError = const AuthErrorNetworkIssue();
    } catch (e) {
      isCouponLoaded = false;
      appState.authError = const AuthErrorUnknownIssue();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future deleteCoupon({
    required CouponDataModel coupon,
  }) async {
    isLoadingLocally = true;
    try {
      final response = await UserProfileRepo.deleteCoupon(couponId: coupon.id);
      if (response.statusCode == 200) {
        userSellingCouponsList.removeWhere((c) => c.id == coupon.id);
        dashboardStore.deleteCouponLocally(coupon: coupon);
        isLoadingLocally = false;
        appState.canDialogPop = true;
      } else {}
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      isLoadingLocally = false;
    }
  }

  @action
  Future updateCoupon({
    required CouponDataModel coupon,
  }) async {
    isLoadingLocally = true;
    try {
      final response = await UserProfileRepo.updateCoupon(coupon: coupon);
      if (response.statusCode == 200) {
        updateCouponLocally(coupon: coupon);
        isLoadingLocally = false;
        appState.canDialogPop = true;
      } else {
        appState.authError = const AuthErrorUnknownIssue();
      }
    } on SocketException {
      appState.authError = const AuthErrorNetworkIssue();
    } on ClientException {
      appState.authError = const AuthErrorNetworkIssue();
    } on TimeoutException {
      appState.authError = const AuthErrorNetworkIssue();
    } catch (e) {
      appState.authError = const AuthErrorUnknownIssue();
    } finally {
      isLoadingLocally = false;
    }
  }

  @action
  void updateCouponLocally({required CouponDataModel coupon}) {
    final index = userSellingCouponsList.indexWhere((c) => c.id == coupon.id);
    userSellingCouponsList[index] = coupon;
    dashboardStore.updateCouponLocally(coupon: coupon);
  }
}
