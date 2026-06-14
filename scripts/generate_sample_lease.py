"""Generate sample_lease.pdf for smoke testing."""

from pathlib import Path

from fpdf import FPDF

OUTPUT = Path(__file__).resolve().parent.parent / "samples" / "sample_lease.pdf"

LINES = [
    "RESIDENTIAL LEASE AGREEMENT",
    "",
    "Property Address: 742 Evergreen Terrace",
    "City: Springfield",
    "State: IL",
    "ZIP Code: 62704",
    "Unit Number: 2B",
    "",
    "Landlord: Springfield Property Management LLC",
    "Tenants: Homer Simpson, Marge Simpson",
    "",
    "Lease Start Date: 2025-01-01",
    "Lease End Date: 2025-12-31",
    "",
    "Monthly Rent: 1850.00",
    "Security Deposit: 1850.00",
    "Late Fee: 75.00",
    "",
    "This lease agreement is entered into between the Landlord and Tenants",
    "for the rental of the property described above.",
]


def main() -> None:
    pdf = FPDF()
    pdf.set_margins(20, 20, 20)
    pdf.add_page()
    pdf.set_font("Helvetica", size=12)

    for line in LINES:
        pdf.cell(0, 8, line, new_x="LMARGIN", new_y="NEXT")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pdf.output(str(OUTPUT))
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    main()
