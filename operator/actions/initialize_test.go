package actions

import (
	"strings"
	"testing"
)

func Test_parseStatus(t *testing.T) {
	stdout := `
id	address	sql_address	build	started_at	updated_at	locality	is_available	is_live	replicas_leaders	replicas_leaseholders	ranges	ranges_unavailable	ranges_underreplicated	live_bytes	key_bytes	value_bytes	intent_bytes	system_bytes	gossiped_replicas	is_decommissioning	is_draining
1	cockroachdb-basic-0.cockroachdb-basic.default.svc.cluster.local:26257	cockroachdb-basic-0.cockroachdb-basic.default.svc.cluster.local:26257	v20.1.0	2020-05-23 17:48:27.739773+00:00	2020-05-23 18:37:57.762499+00:00		true	true	13	13	32	0	0	32256729	216458	32160705	0	35098	32	false	false
2	cockroachdb-basic-1.cockroachdb-basic.default.svc.cluster.local:26257	cockroachdb-basic-1.cockroachdb-basic.default.svc.cluster.local:26257	v20.1.0	2020-05-23 17:48:27.963981+00:00	2020-05-23 18:37:58.53086+00:00		true	true	8	8	32	0	0	32290475	216470	32194474	0	35098	32	false	false
3	cockroachdb-basic-2.cockroachdb-basic.default.svc.cluster.local:26257	cockroachdb-basic-2.cockroachdb-basic.default.svc.cluster.local:26257	v20.1.0	2020-05-23 17:48:28.726112+00:00	2020-05-23 18:37:58.769248+00:00		true	true	11	11	32	0	0	32324221	216482	32228243	0	35098	32	false	false
4	cockroachdb-basic-4.cockroachdb-basic.default.svc.cluster.local:26257	cockroachdb-basic-4.cockroachdb-basic.default.svc.cluster.local:26257	v20.1.0	2020-05-23 18:35:14.928669+00:00	2020-05-23 18:37:57.549187+00:00		true	true	0	0	0	0	0	0	0	0	0	0	0	true	false
8	cockroachdb-basic-3.cockroachdb-basic.default.svc.cluster.local:26257	cockroachdb-basic-3.cockroachdb-basic.default.svc.cluster.local:26257	v20.1.0	2020-05-23 18:35:14.923954+00:00	2020-05-23 18:37:57.571877+00:00		true	true	0	0	0	0	0	0	0	0	0	0	0	true	false
`
	status, err := parseStatus(stdout)
	if err != nil {
		t.Errorf("failed to parse status: %v", err)
	}

	for i, expected := range []NodeStatus{{
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
	}} {
		if status[i].ID != expected.ID {
			t.Errorf("ID was parsed incorrectly, expected %d got %d", expected.ID, status[i].ID)
		}
		if !strings.HasPrefix(status[i].Address, expected.Address) {
			t.Errorf("address was parsed incorrectly, expected %s got %s", expected.Address, status[i].Address)
		}
		if status[i].Available != expected.Available {
			t.Errorf("available was parsed incorrectly, expected %v got %v", expected.Available, status[i].Available)
		}
		if status[i].Live != expected.Live {
			t.Errorf("live was parsed incorrectly, expected %v got %v", expected.Live, status[i].Live)
		}
		if status[i].Decommissioning != expected.Decommissioning {
			t.Errorf("decommissioning was parsed incorrectly, expected %v got %v", expected.Decommissioning, status[i].Decommissioning)
		}
		if status[i].Draining != expected.Draining {
			t.Errorf("draining was parsed incorrectly, expected %v got %v", expected.Draining, status[i].Draining)
		}
	}
}
