This was the output of me following along with great Tutorial from https://github.com/kelseyhightower/kubernetes-the-hard-way. No way I could have done any of this without that documentation!
# TODO
* Get Cilium working

# Getting Started
You'll need:
 * vagrant (tested with 2.0.0)
 * Virtual Box as the provisioner (tested with 5.1.30r118389)

If you have started a cluster before, remember to clear out your certs!
`rm -rf salt-base/file_root/certs/*`
# Create Cluster
1. `export NUM_WORKERS=4`
    This sets the number of workes you'll create. Less than 3 isn't really helpful.
1. `./tools/up-all.sh`

    You may be asked about bridging this is the adapter you want to be able to see the ingress address from, so chose correctly. ( Probably not docker0 )
1. Now go get a coffee.
    You'll know the VM creation is done when you see somethign like this:
    ```bash
    Creating cluster ... ID: 20e5c29fbd15d6cc49d4267133b1f8df
        Creating node 172.17.8.101 ... ID: 8d975dc376a6e0aab07f8339f6cb6bd7
                Adding device /dev/sdc ... OK
        Creating node 172.17.8.102 ... ID: 2ae5ec96fe57c6e543bf224c369f4911
                Adding device /dev/sdc ... OK
        Creating node 172.17.8.103 ... ID: c57abff0fa232c84b4a173f0a8b016e5
                Adding device /dev/sdc ... OK
        Creating node 172.17.8.104 ... ID: 9b7a9cc0d4e71be9f0401e73fef2d36e
                Adding device /dev/sdc ... OK

    ```
1. `vagrant ssh master -c "sudo salt '*' test.ping"`

    ```bash
    node-2.local:
        True
    node-3.local:
        True
    node-4.local:
        True
    node-1.local:
        True
    master.local:
        True    
    ```
1. `vagrant ssh master -c "sudo salt '*' --async state.highstate"`

    this will give you a job ID for keeping an eye on things
1. Go get another coffee
1. `vagrant ssh master -c "watch -c -d -n 30 sudo salt \'*\' saltutil.find_job <jobid>"`

    This allows you to keep an eye on the nodes as they get setup, when this output disappears your cluster is ready. Don't be alarmed if you see things like the minion did not return, sometimes they are pretty busy.
1. `./tools/getAdminConfig.sh`


    This will make an admin.kubeconfig available for you to use on a machine to communicate with the cluster. Move this into ~./kube/config or reference it in kubectl commands

# Check setup
1. `kubectl get nodes`

    You should see all nodes report they are ready e.g.:
    ```bash
    NAME           STATUS    ROLES     AGE       VERSION
    node-1.local   Ready     <none>    2m        v1.8.3
    node-2.local   Ready     <none>    2m        v1.8.3
    node-3.local   Ready     <none>    2m        v1.8.3
    node-4.local   Ready     <none>    2m        v1.8.3
    ```
1. `kubectl -n kube-system get pods`
    Should be someting like:
    ```bash
    NAME                                    READY     STATUS    RESTARTS   AGE
    kube-dns-7797cb8758-ch4p7               3/3       Running   0          7m
    kube-dns-7797cb8758-gm2p4               3/3       Running   0          7m
    kubernetes-dashboard-7486b894c6-9gzdt   1/1       Running   0          7m
    ```
1. `kubectl -n kube-system port-forward $(kubectl -n kube-system get pods -l k8s-app=kubernetes-dashboard -o jsonpath="{.items[0].metadata.name}") :8443`
    
    This forwards a local port to the dashboard. Open the URL that is output but with https://
1. Make sure you see https://127.0.0.1:PORT/#!/overview?namespace=ingress-nginx a successful deployment
1. Make sure you see "gluster" here: https://127.0.0.1:PORT/#!/storageclass?namespace=_all

# Deploy an App
1. `vagrant ssh master -c "ifconfig enp0s9 | grep 'inet ' | tr -s ' ' | cut -d ' ' -f3"`
    This is the IP that should be routable to your master from the LAN.
1. Edit your hosts file on the machine you want to talk to the cluster add:
    <IP> sample.com
1. `vagrant ssh master -c "/opt/bin/kubernetes/server/bin/kubectl create -f /opt/k8s/conf/deploys/gluster/nginx-gluster.yaml"`
1. `curl http://sample.com:30080/`
    This should produce this output:
    ```
    <html>
    <head><title>403 Forbidden</title></head>
    <body bgcolor="white">
    <center><h1>403 Forbidden</h1></center>
    <hr><center>nginx/1.11.1</center>
    </body>
    </html>
    ```
1. `curl http://<ip>:30080/`
    And this should produce this output:
    ```
    default backend - 404%
    ```

What happend?!
The cluster is provisioned out of the gate with a few extras.
1. Gluster a distrubuted file system, which the "App" mounts
1. Nginx Ingress which the App requests.

When you hit sample.com you are hitting the routing rule for the app you deployed which is an nginx container that mounts a gluster disk. When you hit the public IP directly you don't match any rules and get the "default backend".

# Monitoring
If you want monitoring which you should above and beyond the dashboard go and install coreos' prometheus operator:
```
git clone https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus`
cd prometheus-operator
cd contrib/kube-prometheus/
hack/cluster-monitoring/deploy
kubectl apply -f manifests/k8s/self-hosted
```
