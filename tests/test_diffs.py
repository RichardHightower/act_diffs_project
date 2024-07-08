import pytest
from diffs.core import create_patches, apply_patches, Section, Transaction, apply_transaction

def test_create_and_apply_patches():
    text1 = "Hello, world!"
    text2 = "Hello, beautiful world!"
    patches = create_patches(text1, text2)
    assert apply_patches(text1, patches) == text2

def test_apply_transaction():
    original_text = "This is the original text."
    new_text = "This is the updated text."
    patches = create_patches(original_text, new_text)
    
    section = Section("test_section", original_text)
    transaction = Transaction(patches)
    
    updated_section = apply_transaction(section, transaction)
    assert updated_section.text == new_text
    assert updated_section.section_type == "test_section"
