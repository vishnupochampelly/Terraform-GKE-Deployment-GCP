import subprocess
import json
import time
import datetime
import os

CHECK_INTERVAL = 60  # seconds
drift_active = False

def run_terraform_plan():
    print("Running terraform plan...")
    
    result = subprocess.run(
        ["terraform", "plan", "-detailed-exitcode", "-out=tfplan"],
        capture_output=True,
        text=True
    )

    return result.returncode

def generate_drift_json():
    subprocess.run(["terraform", "show", "-json", "tfplan"], stdout=open("plan.json", "w"))

    with open("plan.json") as f:
        data = json.load(f)

    drift_resources = []

    for resource in data.get("resource_changes", []):
        if "update" in resource["change"]["actions"]:

            changes = resource["change"].get("after", {})
            before = resource["change"].get("before", {})

            drift_resources.append({
                "resource": resource["address"],
                "type": resource["type"],
                "action": resource["change"]["actions"],
                "drift_field": "master_authorized_networks_config"
            })

    drift_report = {
        "timestamp": str(datetime.datetime.now()),
        "drift_detected": True,
        "resource_count": len(drift_resources),
        "resources": drift_resources
    }

    return drift_report


def send_alert(report):
    print("\n🚨 DRIFT DETECTED 🚨")
    print(json.dumps(report, indent=4))

    # OPTIONAL: Slack webhook
    # import requests
    # requests.post("YOUR_WEBHOOK_URL", json={"text": json.dumps(report, indent=2)})

def main():
    print("🚀 Terraform Drift Guard Agent Started...\n")

    while True:
        now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"Checking drift at {now} ...")

        exit_code = run_terraform_plan()

        if exit_code == 0:
            print(f"✅ No drift detected at {now}\n")

        elif exit_code == 2:
            report = generate_drift_json()
            print(f"🚨 Drift detected at {now}")
            print(json.dumps(report, indent=2))
            print("\n")

        else:
            print(f"❌ Terraform error at {now}\n")

        time.sleep(30)  # check every 30 seconds


if __name__ == "__main__":
    main()
