#!/usr/bin/env python3
"""
Fix blanks by aligning question_text (with ______) against answer_text word-by-word.

Rules:
1. question_text defines which positions are blanks
2. answer_text defines the correct full sentence
3. blanks = answer words at blank positions in question_text
4. If question_text has more blanks than answer words at those positions,
   collapse blanks (e.g. "herself" → 1 blank, not 3)
5. If question_text has fewer blanks, split them
"""
import json
import re


def stripped(s):
    return ''.join(c for c in s.lower() if c.isalpha() or c.isdigit() or c == "'")


def is_blank(word):
    clean = re.sub(r'[.,?!:;]', '', word)
    return bool(re.match(r'^_+$', clean))


def get_punct(word):
    m = re.search(r'([.,?!:;]+)$', word)
    return m.group(1) if m else ''


def fix_entry(answer_text, question_text):
    """
    Align answer_text and question_text to produce correct blanks + question_text.
    Returns (new_blanks, new_question_text).
    """
    ans_words = answer_text.split()
    qt_words = question_text.split()

    # Step 1: Find all visible (non-blank) words in question_text with their stripped form
    visible_anchors = []  # [(qt_index, stripped_form)]
    for i, w in enumerate(qt_words):
        if not is_blank(w):
            visible_anchors.append((i, stripped(w)))

    # Step 2: Match visible anchors to answer words using LCS-like greedy forward matching
    # This gives us the alignment: which answer words correspond to visible qt words
    anchor_to_ans = {}  # qt_index -> ans_index
    ai = 0
    for qt_i, qt_str in visible_anchors:
        for search_ai in range(ai, len(ans_words)):
            if stripped(ans_words[search_ai]) == qt_str:
                anchor_to_ans[qt_i] = search_ai
                ai = search_ai + 1
                break

    # Step 3: Determine blank regions
    # Between consecutive anchors (and before first / after last),
    # the answer words that aren't anchored are the blank words
    anchored_ans = set(anchor_to_ans.values())

    # Build ordered list of (qt_range, ans_range) for blank regions
    # Sort anchors by qt_index
    sorted_anchors = sorted(anchor_to_ans.items())  # [(qt_i, ans_i), ...]

    new_blanks = []
    new_qt_words = []

    prev_qt = -1
    prev_ans = -1

    for qt_i, ans_i in sorted_anchors:
        # Blank region: qt[prev_qt+1 .. qt_i-1] corresponds to ans[prev_ans+1 .. ans_i-1]
        blank_qt_start = prev_qt + 1
        blank_qt_end = qt_i  # exclusive
        blank_ans_start = prev_ans + 1
        blank_ans_end = ans_i  # exclusive

        # Answer words in this blank region
        blank_ans_words = ans_words[blank_ans_start:blank_ans_end]

        # How many qt blanks in this region
        qt_blank_count = sum(1 for j in range(blank_qt_start, blank_qt_end) if is_blank(qt_words[j]))

        if len(blank_ans_words) == qt_blank_count:
            # Perfect match: one blank per answer word
            bi = 0
            for j in range(blank_qt_start, blank_qt_end):
                if is_blank(qt_words[j]):
                    punct = get_punct(qt_words[j])
                    new_blanks.append(blank_ans_words[bi].rstrip('.,?!:;'))
                    new_qt_words.append('______' + punct)
                    bi += 1
                else:
                    new_qt_words.append(qt_words[j])
        else:
            # Mismatch: rebuild this region with one blank per answer word
            for aw in blank_ans_words:
                new_blanks.append(aw.rstrip('.,?!:;'))
                new_qt_words.append('______')
            # Add punct from last qt blank in region if any
            last_blank_punct = ''
            for j in range(blank_qt_end - 1, blank_qt_start - 1, -1):
                if is_blank(qt_words[j]):
                    last_blank_punct = get_punct(qt_words[j])
                    break
            if last_blank_punct and new_qt_words:
                new_qt_words[-1] = new_qt_words[-1] + last_blank_punct

        # Add the anchor word itself
        new_qt_words.append(qt_words[qt_i])
        prev_qt = qt_i
        prev_ans = ans_i

    # Handle trailing blank region (after last anchor)
    blank_qt_start = (sorted_anchors[-1][0] + 1) if sorted_anchors else 0
    blank_ans_start = (sorted_anchors[-1][1] + 1) if sorted_anchors else 0

    trailing_ans = ans_words[blank_ans_start:]
    trailing_qt_blanks = [j for j in range(blank_qt_start, len(qt_words)) if is_blank(qt_words[j])]
    trailing_qt_visible = [(j, qt_words[j]) for j in range(blank_qt_start, len(qt_words)) if not is_blank(qt_words[j])]

    if len(trailing_ans) == len(trailing_qt_blanks) and not trailing_qt_visible:
        # Perfect match
        bi = 0
        for j in range(blank_qt_start, len(qt_words)):
            if is_blank(qt_words[j]):
                punct = get_punct(qt_words[j])
                new_blanks.append(trailing_ans[bi].rstrip('.,?!:;'))
                new_qt_words.append('______' + punct)
                bi += 1
            else:
                new_qt_words.append(qt_words[j])
    else:
        # Rebuild
        for aw in trailing_ans:
            punct = get_punct(aw)
            new_blanks.append(aw.rstrip('.,?!:;'))
            new_qt_words.append('______' + punct)

    new_qt = ' '.join(new_qt_words)
    return new_blanks, new_qt


def verify(answer_text, blanks):
    """Verify buildQuestionText would work."""
    def s(x):
        return ''.join(c for c in x.lower() if c.isalpha() or c.isdigit() or c == "'")
    words = answer_text.split()
    bi = 0
    for w in words:
        if bi < len(blanks) and s(w) == s(blanks[bi]):
            bi += 1
    return bi == len(blanks)


def main():
    fixed = 0
    for lvl in ['level1', 'level2', 'level3']:
        path = f'Assets/Dictation/{lvl}.json'
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        changed = False
        for q in data['questions']:
            new_blanks, new_qt = fix_entry(q['answer_text'], q['question_text'])

            if not verify(q['answer_text'], new_blanks):
                print(f"  WARN [{lvl} id={q['id']}] verify failed!")
                print(f"    answer: {q['answer_text']}")
                print(f"    blanks: {new_blanks}")
                print(f"    qt:     {new_qt}")
                print()
                continue

            if q['blanks'] != new_blanks or q['question_text'] != new_qt:
                if q['blanks'] != new_blanks:
                    print(f"[{lvl} id={q['id']}] blanks: {q['blanks']} -> {new_blanks}")
                if q['question_text'] != new_qt:
                    print(f"  qt: {q['question_text']}")
                    print(f"  ->  {new_qt}")
                print()
                q['blanks'] = new_blanks
                q['question_text'] = new_qt
                changed = True
                fixed += 1

        if changed:
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"  => {path} saved\n")

    print(f"\nTotal fixes: {fixed}")

    # Final check
    print("\n=== Final verification ===")
    total_issues = 0
    for lvl in ['level1', 'level2', 'level3']:
        path = f'Assets/Dictation/{lvl}.json'
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        issues = 0
        for q in data['questions']:
            if not verify(q['answer_text'], q['blanks']):
                issues += 1
                print(f"  FAIL {lvl} id={q['id']}")
            # Check no blank word is visible in qt
            qt_words = q['question_text'].split()
            vis = [stripped(w) for w in qt_words if not is_blank(w)]
            for b in q['blanks']:
                sb = stripped(b)
                # Only flag if the blank word EXACTLY matches a visible word
                # (not just substring like "the" appearing in question with "the" as visible)
                # This is tricky for common words. Skip check for 1-2 char words.
                if len(sb) > 2 and sb in vis:
                    issues += 1
                    print(f"  VISIBLE [{lvl} id={q['id']}] blank '{b}' visible in qt: {q['question_text']}")
                    break
        total_issues += issues
        print(f"  {lvl}: {len(data['questions'])} questions, {issues} issues")
    print(f"\nTotal issues: {total_issues}")


if __name__ == '__main__':
    main()
