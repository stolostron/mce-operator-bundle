FROM scratch

COPY ./manifests /manifests
COPY ./metadata /metadata
COPY ./extras /extras

LABEL com.redhat.delivery.operator.bundle="true" \
      operators.operatorframework.io.bundle.mediatype.v1="registry+v1" \
      operators.operatorframework.io.bundle.manifests.v1="manifests/" \
      operators.operatorframework.io.bundle.metadata.v1="metadata/" \
      operators.operatorframework.io.bundle.package.v1="multicluster-engine" \
      operators.operatorframework.io.bundle.channels.v1="stable-2.17" \
      operators.operatorframework.io.bundle.channel.default.v1="stable-2.17" \
      com.redhat.openshift.versions="v4.19-v4.23"

LABEL com.redhat.component="multicluster-engine-operator-bundle-container" \
      name="multicluster-engine/mce-operator-bundle" \
      version="2.17.0-23" \
      summary="multicluster-engine-operator-bundle" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="multicluster-engine-operator-bundle" \
      io.k8s.description="Operator bundle for Red Hat Multicluster engine" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="multicluster-engine-operator-bundle" \
      konflux.additional-tags="v2.17.0-23,snapshot-release-mce-217-20260218-002533-000" \
      vendor="Red Hat, Inc." \
      url="https://github.com/stolostron/mce-operator-bundle" \
      release="2.17.0-23" \
      distribution-scope="public" \
      cpe="cpe:/a:redhat:multicluster_engine:2.17::el9"
