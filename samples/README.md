# Sample lease for smoke testing

Use `sample_lease.pdf` to test the upload → extract → review → save flow.

## Expected extracted values

| Field | Expected value |
|-------|----------------|
| Property address | 742 Evergreen Terrace |
| City | Springfield |
| State | IL |
| ZIP | 62704 |
| Unit | 2B |
| Landlord | Springfield Property Management LLC |
| Tenants | Homer Simpson, Marge Simpson |
| Lease start | 2025-01-01 |
| Lease end | 2025-12-31 |
| Monthly rent | 1850.00 |
| Security deposit | 1850.00 |
| Late fee | 75.00 |

## How to test

1. Run the app on **Windows desktop** (not web):
   ```powershell
   flutter pub get
   flutter run -d windows
   ```
2. Sign up or sign in
3. Tap **Upload Lease** and select `samples/sample_lease.pdf`
4. Confirm fields on the review screen, then **Save Lease**
5. Verify the property appears on the Portfolio screen

## Regenerate PDF

```powershell
pip install fpdf2
python scripts/generate_sample_lease.py
```
