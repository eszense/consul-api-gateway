package consul

import (
	capi "github.com/hashicorp/consul/api"
)

const (
	WildcardNamespace = "*"
	DefaultNamespace  = "default"
)

// EnsureNamespaceExists ensures a Consul namespace with name ns exists. If it doesn't,
// it will create it and set crossNSACLPolicy as a policy default.
// Boolean return value indicates if the namespace was created by this call.
func EnsureNamespaceExists(client Client, ns string) (bool, error) {
	if ns == WildcardNamespace || ns == DefaultNamespace {
		return false, nil
	}

	// Check if the Consul namespace exists.
	namespaceInfo, _, err := client.Namespaces().Read(ns, nil)
	if err != nil {
		return false, err
	}
	if namespaceInfo != nil {
		return false, nil
	}

	// If not, create it.
	var aclConfig capi.NamespaceACLConfig

	consulNamespace := capi.Namespace{
		Name:        ns,
		Description: "Auto-generated by consul-api-gateway",
		ACLs:        &aclConfig,
		Meta:        map[string]string{"external-source": "kubernetes"},
	}

	_, _, err = client.Namespaces().Create(&consulNamespace, nil)
	if err != nil {
		return false, err
	}
	return true, err
}
