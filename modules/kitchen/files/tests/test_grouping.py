#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import datetime as dt
import unittest

from kitchen import grouping
from kitchen.calendar_source import Occurrence


def occ(day):
    return Occurrence(title="x", day=day, all_day=True, start_time=None,
                      end_time=None, location=None, multi_day=False)


class SectionForTests(unittest.TestCase):
    # Wednesday 2026-07-22 as "today".
    TODAY = dt.date(2026, 7, 22)

    def test_today_is_this_week(self):
        self.assertEqual(grouping.section_for(self.TODAY, self.TODAY),
                         grouping.THIS_WEEK)

    def test_this_friday_is_this_week(self):
        self.assertEqual(grouping.section_for(dt.date(2026, 7, 24), self.TODAY),
                         grouping.THIS_WEEK)

    def test_saturday_is_this_weekend(self):
        self.assertEqual(grouping.section_for(dt.date(2026, 7, 25), self.TODAY),
                         grouping.THIS_WEEKEND)

    def test_sunday_is_this_weekend(self):
        self.assertEqual(grouping.section_for(dt.date(2026, 7, 26), self.TODAY),
                         grouping.THIS_WEEKEND)

    def test_next_monday_is_next_week(self):
        self.assertEqual(grouping.section_for(dt.date(2026, 7, 27), self.TODAY),
                         grouping.NEXT_WEEK)

    def test_next_sunday_is_next_week(self):
        self.assertEqual(grouping.section_for(dt.date(2026, 8, 2), self.TODAY),
                         grouping.NEXT_WEEK)

    def test_beyond_next_week_is_future(self):
        self.assertEqual(grouping.section_for(dt.date(2026, 8, 3), self.TODAY),
                         grouping.FUTURE)

    def test_past_day_is_none(self):
        self.assertIsNone(grouping.section_for(dt.date(2026, 7, 21), self.TODAY))


class WeekendTodayTests(unittest.TestCase):
    # Saturday 2026-07-25 as "today": This week should be empty.
    TODAY = dt.date(2026, 7, 25)

    def test_saturday_today_in_weekend(self):
        self.assertEqual(grouping.section_for(self.TODAY, self.TODAY),
                         grouping.THIS_WEEKEND)


class GroupTests(unittest.TestCase):
    TODAY = dt.date(2026, 7, 22)

    def test_group_orders_and_filters_sections(self):
        occs = [
            occ(dt.date(2026, 7, 22)),   # this week
            occ(dt.date(2026, 7, 25)),   # this weekend
            occ(dt.date(2026, 8, 10)),   # future
        ]
        result = grouping.group(occs, self.TODAY)
        names = [name for name, _ in result]
        self.assertEqual(names, [grouping.THIS_WEEK, grouping.THIS_WEEKEND,
                                 grouping.FUTURE])
        # Next week omitted because empty.
        self.assertNotIn(grouping.NEXT_WEEK, names)


if __name__ == "__main__":
    unittest.main()
