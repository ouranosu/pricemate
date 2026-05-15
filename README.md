# PriceMate

PriceMate is a Flutter mobile app for sharing grocery price standards and shopping lists with partners or family members.

## MVP Scope

- Email, Google, and Apple authentication with Firebase Authentication
- Family/shared-space based data sharing
- Invite URL flow with one-time tokens
- Product price standards
  - product name
  - store name
  - optional size
  - best price
  - acceptable price
  - sale weekdays
- Shopping list
  - product name
  - urgency: now or later
- Purchase history
- Five-tab mobile UI
  - Home
  - Shopping list
  - Input with prominent center plus button
  - Product list
  - Settings

## Firebase Data Shape

```text
users/{userId}
sharedSpaces/{spaceId}
sharedSpaces/{spaceId}/members/{userId}
sharedSpaces/{spaceId}/products/{productId}
sharedSpaces/{spaceId}/shoppingItems/{itemId}
sharedSpaces/{spaceId}/purchaseRecords/{recordId}
invites/{inviteId}
```

## Recommended Firebase Services

- Firebase Authentication
- Cloud Firestore
- Cloud Functions
- Firebase Cloud Messaging
- Cloud Storage

Firebase Dynamic Links should not be used for invites. Use Universal Links and Android App Links with a custom invite token endpoint instead.

## Later Features

- LINE login via Firebase Custom Auth
- Barcode scanning
- Receipt image upload and OCR
- Unit price comparison
- Sale day notifications
- Price trend charts
