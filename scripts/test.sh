#!/bin/bash

set -exu

mvn clean package docker:build

kubectl apply -f kubernetes/akka-cluster.yml

for i in {1..10}
do
  echo "Waiting for pods to get ready..."
  kubectl get pods
  [ `kubectl get pods | grep Running | wc -l` -eq 2 ] && break
  sleep 4
done

if [ $i -eq 10 ]
then
  echo "Pods did not get ready"
  exit -1
fi

POD=$(kubectl get pods | grep appka | grep Running | head -n1 | awk '{ print $1 }')

for i in {1..10}
do
  echo "Checking for MemberUp logging..."
  kubectl logs $POD | grep MemberUp || true
  [ `kubectl logs $POD | grep MemberUp | wc -l` -eq 2 ] && break
  sleep 3
done

kubectl get pods

echo "Logs"
echo "=============================="
for POD in $(kubectl get pods | grep appka | grep Running | awk '{ print $1 }')
do
  echo "Logging for $POD"
  kubectl logs $POD
done

if [ $i -eq 10 ]
then
  echo "No 2 MemberUp log events found"
  echo "=============================="

  exit -1
fi
