FROM scratch

COPY ./manifests /manifests
COPY ./metadata /metadata
COPY ./extras /extras

LABEL com.redhat.delivery.operator.bundle="true" \
      operators.operatorframework.io.bundle.mediatype.v1="registry+v1" \
      operators.operatorframework.io.bundle.manifests.v1="manifests/" \
      operators.operatorframework.io.bundle.metadata.v1="metadata/" \
      operators.operatorframework.io.bundle.package.v1="multicluster-engine" \
      operators.operatorframework.io.bundle.channels.v1="stable-2.11" \
      operators.operatorframework.io.bundle.channel.default.v1="stable-2.11" \
      com.redhat.openshift.versions="v4.18-v4.22"

LABEL com.redhat.component="multicluster-engine-operator-bundle-container" \
      name="multicluster-engine/mce-operator-bundle" \
      version="2.11.0-291" \
      summary="multicluster-engine-operator-bundle" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="multicluster-engine-operator-bundle" \
      io.k8s.description="Operator bundle for Red Hat Multicluster engine" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="multicluster-engine-operator-bundle" \
      konflux.additional-tags="v2.11.0-291,snapshot-release-mce-211-20260224-153804-000" \
      vendor="Red Hat, Inc." \
      url="https://github.com/stolostron/mce-operator-bundle" \
      release="2.11.0-291" \
      distribution-scope="public" \
      cpe="cpe:/a:redhat:multicluster_engine:2.11::el9"
