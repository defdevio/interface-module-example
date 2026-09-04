package test

import (
	"context"
	"fmt"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func TestInterfaceModulePlan(t *testing.T) {
	ctx := context.Background()
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "..", ".")

	options := &terraform.Options{
		TerraformDir: terraformDir,
		PlanFilePath: filepath.Join(t.TempDir(), "interface-module.tfplan"),
		EnvVars: map[string]string{
			"AWS_ACCESS_KEY_ID":     "testing",
			"AWS_SECRET_ACCESS_KEY": "testing",
		},
		Vars: map[string]any{
			"account_id":                      "123456789012",
			"aws_skip_credentials_validation": true,
			"lambda_functions": map[string]any{
				"orders": map[string]any{
					"spec": map[string]any{
						"description": "Processes order events",
						"ecr": map[string]any{
							"image_tag": "2026.09.1",
						},
						"environment_variables": map[string]string{
							"NODE_ENV": "dev",
						},
						"custom_iam_policy_statements": []map[string]any{
							{
								"sid":       "ReadOrders",
								"actions":   []string{"dynamodb:GetItem"},
								"resources": []string{"arn:aws:dynamodb:us-west-2:123456789012:table/orders"},
							},
						},
					},
				},
			},
			"s3_buckets": map[string]any{
				"order_exports": map[string]any{
					"spec": map[string]any{
						"resource_key_ref": "orders",
					},
				},
				"shared_assets": map[string]any{
					"spec": map[string]any{},
				},
			},
		},
	}

	terraform.InitAndPlanContext(t, ctx, options)
	plan := terraform.ShowWithStructContext(t, ctx, options)
	resourceChanges := plan.ResourceChangesMap

	assert.Contains(t, resourceChanges, fmt.Sprintf(`module.iam.aws_iam_role.this[%q]`, "orders"))
	assert.Contains(t, resourceChanges, fmt.Sprintf(`module.ecr[%q].aws_ecr_repository.this`, "orders"))
	assert.Contains(t, resourceChanges, fmt.Sprintf(`module.lambda_functions[%q].aws_lambda_function.this`, "orders"))
	assert.Contains(t, resourceChanges, fmt.Sprintf(`module.s3[%q].aws_s3_bucket.this`, "order_exports"))
	assert.Contains(t, resourceChanges, fmt.Sprintf(`module.s3[%q].aws_s3_bucket.this`, "shared_assets"))
}

func TestInterfaceModuleRejectsUnknownS3Reference(t *testing.T) {
	ctx := context.Background()
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "..", ".")

	options := &terraform.Options{
		TerraformDir: terraformDir,
		EnvVars: map[string]string{
			"AWS_ACCESS_KEY_ID":     "testing",
			"AWS_SECRET_ACCESS_KEY": "testing",
		},
		Vars: map[string]any{
			"account_id":                      "123456789012",
			"aws_skip_credentials_validation": true,
			"s3_buckets": map[string]any{
				"broken": map[string]any{
					"spec": map[string]any{
						"resource_key_ref": "missing-function",
					},
				},
			},
		},
	}

	terraform.InitContext(t, ctx, options)
	_, err := terraform.PlanContextE(t, ctx, options)
	assert.Error(t, err)
}
