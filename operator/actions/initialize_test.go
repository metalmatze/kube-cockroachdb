package actions

import (
	"strings"
	"testing"
)

func Test_parseStatus(t *testing.T) {
	cases := []struct {
		name     string
		input    string
		expected []NodeStatus
	}{
		{
			name: "standard",
			input: `
id	address	sql_address	build	started_at	updated_at	locality	is_available	is_live	replicas_leaders	replicas_leaseholders	ranges	ranges_unavailable	ranges_underreplicated	live_bytes	key_bytes	value_bytes	intent_bytes	system_bytes	gossiped_replicas	is_decommissioning	is_draining
1	cockroachdb-basic-0.cockroachdb-basic.default.svc.cluster.local:26257	cockroachdb-basic-0.cockroachdb-basic.default.svc.cluster.local:26257	v20.1.0	2020-05-23 17:48:27.739773+00:00	2020-05-23 18:37:57.762499+00:00		true	true	13	13	32	0	0	32256729	216458	32160705	0	35098	32	false	false
2	cockroachdb-basic-1.cockroachdb-basic.default.svc.cluster.local:26257	cockroachdb-basic-1.cockroachdb-basic.default.svc.cluster.local:26257	v20.1.0	2020-05-23 17:48:27.963981+00:00	2020-05-23 18:37:58.53086+00:00		true	true	8	8	32	0	0	32290475	216470	32194474	0	35098	32	false	false
3	cockroachdb-basic-2.cockroachdb-basic.default.svc.cluster.local:26257	cockroachdb-basic-2.cockroachdb-basic.default.svc.cluster.local:26257	v20.1.0	2020-05-23 17:48:28.726112+00:00	2020-05-23 18:37:58.769248+00:00		true	true	11	11	32	0	0	32324221	216482	32228243	0	35098	32	false	false
4	cockroachdb-basic-4.cockroachdb-basic.default.svc.cluster.local:26257	cockroachdb-basic-4.cockroachdb-basic.default.svc.cluster.local:26257	v20.1.0	2020-05-23 18:35:14.928669+00:00	2020-05-23 18:37:57.549187+00:00		true	true	0	0	0	0	0	0	0	0	0	0	0	true	false
8	cockroachdb-basic-3.cockroachdb-basic.default.svc.cluster.local:26257	cockroachdb-basic-3.cockroachdb-basic.default.svc.cluster.local:26257	v20.1.0	2020-05-23 18:35:14.923954+00:00	2020-05-23 18:37:57.571877+00:00		true	true	0	0	0	0	0	0	0	0	0	0	0	true	false
`,
			expected: []NodeStatus{{
				ID:              1,
				Address:         "cockroachdb-basic-0",
				Available:       true,
				Live:            true,
				Decommissioning: false,
				Draining:        false,
			}, {
				ID:              2,
				Address:         "cockroachdb-basic-1",
				Available:       true,
				Live:            true,
				Decommissioning: false,
				Draining:        false,
			}, {
				ID:              3,
				Address:         "cockroachdb-basic-2",
				Available:       true,
				Live:            true,
				Decommissioning: false,
				Draining:        false,
			}, {
				ID:              4,
				Address:         "cockroachdb-basic-4",
				Available:       true,
				Live:            true,
				Decommissioning: true,
				Draining:        false,
			}, {
				ID:              8,
				Address:         "cockroachdb-basic-3",
				Available:       true,
				Live:            true,
				Decommissioning: true,
				Draining:        false,
			}},
		},
		{
			name: "v20",
			// v20 added the "membership" column.
			input: `
id	address	sql_address	build	started_at	updated_at	locality	is_available	is_live	replicas_leaders	replicas_leaseholders	ranges	ranges_unavailable	ranges_underreplicated	live_bytes	key_bytes	value_bytes	intent_bytes	system_bytes	gossiped_replicas	is_decommissioning	membership	is_draining
1	cockroachdb-cockroachdb-0.cockroachdb-cockroachdb.db.svc.cluster.local:26257	cockroachdb-cockroachdb-0.cockroachdb-cockroachdb.db.svc.cluster.local:26257	v20.2.3	2022-02-13 09:19:31.671654+00:00	2022-02-13 10:11:03.488379+00:00		true	true	41	41	72	0	72	3082237972	41254331	3047032980	1612	158761	72	false	active	false
2	cockroachdb-cockroachdb-1.cockroachdb-cockroachdb.db.svc.cluster.local:26257	cockroachdb-cockroachdb-1.cockroachdb-cockroachdb.db.svc.cluster.local:26257	v20.2.3	2022-02-13 09:56:12.448711+00:00	2022-02-13 10:01:25.746251+00:00		false	false	26	24	72	0	0	3080325214	41696315	3045892113	1640	447868	0	false	active	false
3	cockroachdb-cockroachdb-2.cockroachdb-cockroachdb.db.svc.cluster.local:26257	cockroachdb-cockroachdb-2.cockroachdb-cockroachdb.db.svc.cluster.local:26257	v20.2.3	2022-02-13 09:28:00.398419+00:00	2022-02-13 10:10:59.203639+00:00		true	true	31	31	72	0	0	3082237972	41254331	3047032980	1612	158761	72	false	active	false
`,
			expected: []NodeStatus{{
				ID:              1,
				Address:         "cockroachdb-cockroachdb-0.cockroachdb-cockroachdb.db.svc.cluster.local:26257",
				Available:       true,
				Live:            true,
				Decommissioning: false,
				Draining:        false,
			}, {
				ID:              2,
				Address:         "cockroachdb-cockroachdb-1.cockroachdb-cockroachdb.db.svc.cluster.local:26257",
				Available:       false,
				Live:            false,
				Decommissioning: false,
				Draining:        false,
			}, {
				ID:              3,
				Address:         "cockroachdb-cockroachdb-2.cockroachdb-cockroachdb.db.svc.cluster.local:26257",
				Available:       true,
				Live:            true,
				Decommissioning: false,
				Draining:        false,
			}},
		},
	}

	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			status, err := parseStatus(testCase.input)
			if err != nil {
				t.Errorf("failed to parse status: %v", err)
			}

			if len(status) != len(testCase.expected) {
				t.Fatalf("expected %d nodes, got %d", len(testCase.expected), len(status))
			}

			for i, expected := range testCase.expected {
				if status[i].ID != expected.ID {
					t.Errorf("row %d ID was parsed incorrectly, expected %d got %d", i, expected.ID, status[i].ID)
				}
				if !strings.HasPrefix(status[i].Address, expected.Address) {
					t.Errorf("row %d address was parsed incorrectly, expected %s got %s", i, expected.Address, status[i].Address)
				}
				if status[i].Available != expected.Available {
					t.Errorf("row %d available was parsed incorrectly, expected %v got %v", i, expected.Available, status[i].Available)
				}
				if status[i].Live != expected.Live {
					t.Errorf("row %d live was parsed incorrectly, expected %v got %v", i, expected.Live, status[i].Live)
				}
				if status[i].Decommissioning != expected.Decommissioning {
					t.Errorf("row %d decommissioning was parsed incorrectly, expected %v got %v", i, expected.Decommissioning, status[i].Decommissioning)
				}
				if status[i].Draining != expected.Draining {
					t.Errorf("row %d draining was parsed incorrectly, expected %v got %v", i, expected.Draining, status[i].Draining)
				}
			}
		})
	}
}
