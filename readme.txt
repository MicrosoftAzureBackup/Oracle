The scripts on this page are provided to you by various third-parties and are licensed to you by those third-parties. Microsoft does not license any intellectual property to you as part of any third-party scripts and is not responsible for information provided by third-parties. Microsoft makes no warranty, express or implied, guarantees or conditions with respect to your use of the scripts. You understand that use of the scripts is at your own risk. Unless otherwise stated by the third-party licensing you the script, the scripts are provided as-is without any warranty or support.

Pre-requisite for running this script
1. Update the conf.sh with Oracle instance ID(SID) and Oracle Home path for each instance in correct order(comma separated list).
2. Make sure log destination folder (as specified in the conf.sh file) exits with appropriate permission.
3. After full IaaSVM restore run the post_restore.sh script with root privilage and provide full path of conf.sh as parameter.
4. If you are directy running the provided scripts please configure following as parameters in VMSnapshotScriptPluginConfig.json file
    "preScriptParams" : ["/scripts/conf.sh", "0"],
    "postScriptParams" : ["/scripts/conf.sh", "1"],
