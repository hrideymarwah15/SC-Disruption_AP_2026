import subprocess
import tempfile
import unittest
from unittest.mock import patch
import run_benchmark as runner


class BenchmarkChecks(unittest.TestCase):
    def test_w15_excludes_transaction_footer(self):
        queries = runner.parse_queries('dbms/04_queries.sql')
        self.assertEqual(len(queries), 33)
        w15 = next(q for q in queries if q['id'] == 'W15')
        self.assertNotIn('COMMIT', w15['sql'].upper())

    def test_snapshot_error_fails(self):
        failed = subprocess.CompletedProcess([], 1, '', 'column does not exist')
        with patch.object(runner.subprocess, 'run', return_value=failed):
            with self.assertRaises(SystemExit):
                runner.snapshot('unused')

    def test_changed_rows_fail_rollback(self):
        with patch.object(runner, 'snapshot', side_effect=[{'row': 'before'}, {'row': 'after'}]), patch.object(runner, 'run_single'):
            with tempfile.TemporaryDirectory() as folder:
                with self.assertRaises(SystemExit):
                    runner.verify_rollback('unused', folder)


if __name__ == '__main__':
    unittest.main()
