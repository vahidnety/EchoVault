package com.echovault.android

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import org.junit.Rule
import org.junit.Test

class ComposeSmokeTest {
    @get:Rule val compose = createAndroidComposeRule<MainActivity>()
    @Test fun appShowsBranding() { compose.onNodeWithText("EchoVault").assertIsDisplayed() }
}
