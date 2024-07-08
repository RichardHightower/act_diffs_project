from diff_match_patch import diff_match_patch
from typing import List

class Transaction:
    def __init__(self, patches: List[str]) -> None:
        self.patches = patches

class Section:
    def __init__(self, section_type: str, text: str) -> None:
        self.section_type = section_type
        self.text = text

def create_patches(text1: str, text2: str) -> List[str]:
    dmp = diff_match_patch()
    patches = dmp.patch_make(text1, text2)
    return dmp.patch_toText(patches)

def apply_patches(text: str, patches: str) -> str:
    dmp = diff_match_patch()
    patched_text, _ = dmp.patch_apply(dmp.patch_fromText(patches), text)
    return patched_text

def apply_transaction(section: Section, transaction: Transaction) -> Section:
    new_text = apply_patches(section.text, transaction.patches)
    return Section(section.section_type, new_text)
