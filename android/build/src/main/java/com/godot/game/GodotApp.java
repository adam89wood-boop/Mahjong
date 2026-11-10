/**************************************************************************/
/*  GodotApp.java                                                         */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

package com.godot.game;

import org.godotengine.godot.Godot;
import org.godotengine.godot.GodotActivity;

import android.os.Bundle;
import android.util.Log;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.appopen.AppOpenAd;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

import androidx.activity.EdgeToEdge;
import androidx.core.splashscreen.SplashScreen;

/**
 * Template activity for Godot Android builds.
 * Feel free to extend and modify this class for your custom logic.
 */
public class GodotApp extends GodotActivity {
	private static final String TAG = "MahjongAds";
	private static final String INTERSTITIAL_AD_UNIT_ID = BuildConfig.DEBUG
			? "ca-app-pub-3940256099942544/1033173712"
			: "ca-app-pub-3918202059564315/8844354140";
	private static final String APP_OPEN_AD_UNIT_ID = BuildConfig.DEBUG
			? "ca-app-pub-3940256099942544/9257395921"
			: "ca-app-pub-3918202059564315/2912324437";

	private InterstitialAd interstitialAd;
	private AppOpenAd appOpenAd;
	private boolean isLoadingInterstitial;
	private boolean isLoadingAppOpen;
	private boolean isShowingAppOpen;
	private boolean hasEnteredForeground;
	static {
		// .NET libraries.
		if (BuildConfig.FLAVOR.equals("mono")) {
			try {
				Log.v("GODOT", "Loading System.Security.Cryptography.Native.Android library");
				System.loadLibrary("System.Security.Cryptography.Native.Android");
			} catch (UnsatisfiedLinkError e) {
				Log.e("GODOT", "Unable to load System.Security.Cryptography.Native.Android library");
			}
		}
	}

	private final Runnable updateWindowAppearance = () -> {
		Godot godot = getGodot();
		if (godot != null) {
			godot.enableImmersiveMode(godot.isInImmersiveMode(), true);
			godot.enableEdgeToEdge(godot.isInEdgeToEdgeMode(), true);
			godot.setSystemBarsAppearance();
		}
	};

	@Override
	public void onCreate(Bundle savedInstanceState) {
		SplashScreen splashScreen = SplashScreen.installSplashScreen(this);
		EdgeToEdge.enable(this);
		super.onCreate(savedInstanceState);
		MobileAds.initialize(this, initializationStatus -> {
			loadInterstitial();
			loadAppOpen();
		});

		Godot godot = getGodot();
		if (godot != null && godot.getDisableGodotSplash()) {
			splashScreen.setKeepOnScreenCondition(() -> godot.getRunStatus() != Godot.RunStatus.STARTED);
		}
	}

	@Override
	public void onResume() {
		super.onResume();
		updateWindowAppearance.run();
		if (hasEnteredForeground) {
			showAppOpenIfAvailable();
		}
		hasEnteredForeground = true;
	}

	private void loadInterstitial() {
		if (isLoadingInterstitial || interstitialAd != null) return;
		isLoadingInterstitial = true;
		InterstitialAd.load(this, INTERSTITIAL_AD_UNIT_ID, new AdRequest.Builder().build(), new InterstitialAdLoadCallback() {
			@Override public void onAdLoaded(InterstitialAd ad) {
				interstitialAd = ad;
				isLoadingInterstitial = false;
			}
			@Override public void onAdFailedToLoad(LoadAdError error) {
				isLoadingInterstitial = false;
				Log.d(TAG, "Interstitial unavailable: " + error.getMessage());
			}
		});
	}

	public void showInterstitial() {
		runOnUiThread(() -> {
			if (interstitialAd == null) {
				loadInterstitial();
				return;
			}
			InterstitialAd ad = interstitialAd;
			interstitialAd = null;
			ad.setFullScreenContentCallback(new FullScreenContentCallback() {
				@Override public void onAdDismissedFullScreenContent() { loadInterstitial(); }
				@Override public void onAdFailedToShowFullScreenContent(AdError error) { loadInterstitial(); }
			});
			ad.show(GodotApp.this);
		});
	}

	private void loadAppOpen() {
		if (isLoadingAppOpen || appOpenAd != null) return;
		isLoadingAppOpen = true;
		AppOpenAd.load(this, APP_OPEN_AD_UNIT_ID, new AdRequest.Builder().build(), new AppOpenAd.AppOpenAdLoadCallback() {
			@Override public void onAdLoaded(AppOpenAd ad) {
				appOpenAd = ad;
				isLoadingAppOpen = false;
			}
			@Override public void onAdFailedToLoad(LoadAdError error) {
				isLoadingAppOpen = false;
				Log.d(TAG, "App-open ad unavailable: " + error.getMessage());
			}
		});
	}

	private void showAppOpenIfAvailable() {
		if (isShowingAppOpen || appOpenAd == null) {
			loadAppOpen();
			return;
		}
		isShowingAppOpen = true;
		AppOpenAd ad = appOpenAd;
		appOpenAd = null;
		ad.setFullScreenContentCallback(new FullScreenContentCallback() {
			@Override public void onAdDismissedFullScreenContent() { isShowingAppOpen = false; loadAppOpen(); }
			@Override public void onAdFailedToShowFullScreenContent(AdError error) { isShowingAppOpen = false; loadAppOpen(); }
		});
		ad.show(this);
	}

	@Override
	public void onGodotMainLoopStarted() {
		super.onGodotMainLoopStarted();
		runOnUiThread(updateWindowAppearance);
	}

	@Override
	public void onGodotForceQuit(Godot instance) {
		if (!BuildConfig.FLAVOR.equals("instrumented")) {
			// For instrumented builds, we disable force-quitting to allow the instrumented tests to complete
			// successfully, otherwise they fail when the process crashes.
			super.onGodotForceQuit(instance);
		}
	}

	@Override
	protected boolean isPiPEnabled() {
		return true;
	}
}
