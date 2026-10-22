#!/usr/bin/env python3
"""Tests for slack_cve_report.py CVE filtering"""

import json
import tempfile
import unittest
from pathlib import Path

from slack_cve_report import parse_grype_json


class TestCVEFiltering(unittest.TestCase):
    """Test CVE filtering functionality"""

    def create_test_grype_json(self, cves):
        """Create a temporary Grype JSON report for testing

        Args:
            cves: List of dicts with 'severity' and 'has_fix' keys

        Returns:
            Path to temporary JSON file
        """
        matches = []
        for i, cve in enumerate(cves):
            match = {
                'vulnerability': {
                    'id': f'CVE-2024-{1000+i}',
                    'severity': cve['severity'],
                    'description': f'Test CVE {i}',
                    'fix': {
                        'versions': [cve.get('fixed_version', '')] if cve.get('has_fix') else []
                    }
                },
                'artifact': {
                    'name': f'test-package-{i}'
                }
            }
            matches.append(match)

        data = {'matches': matches}

        # Write to temp file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(data, f)
            return Path(f.name)

    def test_parse_no_filter(self):
        """Test parsing without filter - should include all CVEs"""
        cves = [
            {'severity': 'CRITICAL', 'has_fix': True, 'fixed_version': '1.2.3'},
            {'severity': 'CRITICAL', 'has_fix': False},
            {'severity': 'HIGH', 'has_fix': True, 'fixed_version': '2.0.0'},
            {'severity': 'HIGH', 'has_fix': False},
        ]

        json_file = self.create_test_grype_json(cves)
        try:
            result = parse_grype_json(json_file, filter_unfixable=False)

            self.assertEqual(result['critical'], 2)
            self.assertEqual(result['high'], 2)
            self.assertEqual(result['total'], 4)
            self.assertEqual(result['has_fix'], 2)
            self.assertEqual(result['no_fix'], 2)
        finally:
            json_file.unlink()

    def test_parse_with_filter(self):
        """Test parsing with filter - should exclude unfixable CVEs"""
        cves = [
            {'severity': 'CRITICAL', 'has_fix': True, 'fixed_version': '1.2.3'},
            {'severity': 'CRITICAL', 'has_fix': False},
            {'severity': 'HIGH', 'has_fix': True, 'fixed_version': '2.0.0'},
            {'severity': 'HIGH', 'has_fix': False},
        ]

        json_file = self.create_test_grype_json(cves)
        try:
            result = parse_grype_json(json_file, filter_unfixable=True)

            # Only fixable CVEs should be counted
            self.assertEqual(result['critical'], 1)
            self.assertEqual(result['high'], 1)
            self.assertEqual(result['total'], 2)
            # Still track fixability stats (counted before filter)
            self.assertEqual(result['has_fix'], 2)
            self.assertEqual(result['no_fix'], 2)
        finally:
            json_file.unlink()

    def test_filter_all_unfixable(self):
        """Test filtering when all CVEs are unfixable"""
        cves = [
            {'severity': 'CRITICAL', 'has_fix': False},
            {'severity': 'HIGH', 'has_fix': False},
            {'severity': 'MEDIUM', 'has_fix': False},
        ]

        json_file = self.create_test_grype_json(cves)
        try:
            result = parse_grype_json(json_file, filter_unfixable=True)

            self.assertEqual(result['critical'], 0)
            self.assertEqual(result['high'], 0)
            self.assertEqual(result['medium'], 0)
            self.assertEqual(result['total'], 0)
            self.assertEqual(result['no_fix'], 3)
        finally:
            json_file.unlink()

    def test_filter_all_fixable(self):
        """Test filtering when all CVEs are fixable - should keep all"""
        cves = [
            {'severity': 'CRITICAL', 'has_fix': True, 'fixed_version': '1.0.0'},
            {'severity': 'HIGH', 'has_fix': True, 'fixed_version': '2.0.0'},
        ]

        json_file = self.create_test_grype_json(cves)
        try:
            result = parse_grype_json(json_file, filter_unfixable=True)

            self.assertEqual(result['critical'], 1)
            self.assertEqual(result['high'], 1)
            self.assertEqual(result['total'], 2)
            self.assertEqual(result['has_fix'], 2)
            self.assertEqual(result['no_fix'], 0)
        finally:
            json_file.unlink()

    def test_cve_details_filtered(self):
        """Test that CVE details list excludes unfixable when filtered"""
        cves = [
            {'severity': 'CRITICAL', 'has_fix': True, 'fixed_version': '1.2.3'},
            {'severity': 'CRITICAL', 'has_fix': False},
        ]

        json_file = self.create_test_grype_json(cves)
        try:
            result = parse_grype_json(json_file, filter_unfixable=True)

            # Only 1 critical CVE with fix should be in details
            self.assertEqual(len(result['details']), 1)
            self.assertEqual(result['details'][0]['fixed_version'], '1.2.3')
        finally:
            json_file.unlink()

    def test_empty_scan(self):
        """Test parsing empty scan results"""
        json_file = self.create_test_grype_json([])
        try:
            result = parse_grype_json(json_file, filter_unfixable=True)

            self.assertEqual(result['total'], 0)
            self.assertEqual(result['critical'], 0)
            self.assertEqual(result['has_fix'], 0)
            self.assertEqual(result['no_fix'], 0)
        finally:
            json_file.unlink()


if __name__ == '__main__':
    unittest.main()
