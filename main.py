from diffs.core import Transaction, Section, create_patches, apply_transaction
import json

large_block_text_1 = """
Section. 1.
All legislative Powers herein granted shall be vested...
"""

large_block_text_2 = """
in a Congress of the United States, which shall consist of a Senate and House of Representatives.

Section. 2.
The House of Representatives shall be composed of Members chosen every second Year by the People of the several States, and the Electors in each State shall have the Qualifications requisite for Electors of the most numerous Branch of the State Legislature.
"""

# Mock database
database = {
    "Introduction": "This is the original introduction.",
    "Body": large_block_text_1 + "This is the body of the document." + large_block_text_2,
    "Conclusion": "This is the conclusion."
}

if __name__ == '__main__':
    # Example usage
    original_body = database["Body"]

    new_body = large_block_text_1 + "*** This is the updated body. ***" + large_block_text_2
    patches = create_patches(original_body, new_body)
    print("Patches:", patches)

    transaction = Transaction(patches)
    section = Section("Body", original_body)

    updated_section = apply_transaction(section, transaction)
    database[updated_section.section_type] = updated_section.text

    print("\nUpdated Section:", updated_section.text)
    print("\nDatabase State:", json.dumps(database, indent=2))
