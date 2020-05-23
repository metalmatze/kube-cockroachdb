/*

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v1alpha1

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// CockroachDBList contains a list of CockroachDB
// +kubebuilder:object:root=true
type CockroachDBList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []CockroachDB `json:"items"`
}

// CockroachDB is the Schema for the a CockroachDB instance managed by the Operator.
// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:subresource:scale:specpath=.spec.replicas,statuspath=.status.replicas,selectorpath=.status.selector
// +kubebuilder:printcolumn:name="Replicas",type="integer",JSONPath=".spec.replicas"
// +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"
type CockroachDB struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   CockroachDBSpec    `json:"spec,omitempty"`
	Status *CockroachDBStatus `json:"status,omitempty"`
}

// CockroachDBSpec defines the desired state of a CockroachDB instance.
type CockroachDBSpec struct {
	Image *string `json:"image"`

	// Define the number of replicas to run for the CockroachDB cluster.
	Replicas *uint32 `json:"replicas,omitempty"`

	// Define resources requests and limits for single Pods.
	Resources corev1.ResourceRequirements `json:"resources,omitempty"`
}

type CockroachDBStatus struct{}

func init() {
	SchemeBuilder.Register(&CockroachDB{}, &CockroachDBList{})
}
