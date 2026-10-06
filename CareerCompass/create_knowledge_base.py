import xml.etree.ElementTree as ET
import re
import html
import json


# Load XML
tree = ET.parse("OOH_xml_compilation.xml")
root = tree.getroot()


def clean_text(text):
    if not text:
        return ""

    # Remove HTML tags
    text = re.sub(r"<[^>]+>", " ", text)

    # Decode HTML entities
    text = html.unescape(text)

    # Clean whitespace
    text = re.sub(r"\s+", " ", text)

    return text.strip()


documents = []

for occupation in root.findall("occupation"):

    occ_code = occupation.findtext("occupation_code")
    occ_title = occupation.findtext("occupation_name_full")

    what_they_do = clean_text(
        occupation.findtext("summary_what_they_do")
    )

    work_environment = clean_text(
        occupation.findtext("summary_work_environment")
    )

    how_to_become = clean_text(
        occupation.findtext("summary_how_to_become_one")
    )

    job_outlook = clean_text(
        occupation.findtext("summary_outlook")
    )

    pay = clean_text(
    occupation.findtext("summary_pay")
    )

    more_information = clean_text(
        occupation.findtext("summary_more_information")
    )

    text = f"""
Occupation: {occ_title}

What They Do:
{what_they_do}

Work Environment:
{work_environment}

How to Become One:
{how_to_become}

Pay:
{pay}

Job Outlook:
{job_outlook}

More Information:
{more_information}
""".strip()

    documents.append({
        "OCC_CODE": occ_code,
        "OCC_TITLE": occ_title,
        "text": text
    })


# Save knowledge base
with open(
    "careercompass_knowledge_base.json",
    "w",
    encoding="utf-8"
) as f:
    json.dump(documents, f, indent=2, ensure_ascii=False)


print(f"Created {len(documents)} occupation documents.")

print("\nFirst document:")
print(documents[0])