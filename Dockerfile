FROM scratch

COPY ./manifests /manifests
COPY ./metadata /metadata
COPY ./extras /extras

LABEL com.redhat.delivery.operator.bundle="true" \
      operators.operatorframework.io.bundle.mediatype.v1="registry+v1" \
      operators.operatorframework.io.bundle.manifests.v1="manifests/" \
      operators.operatorframework.io.bundle.metadata.v1="metadata/" \
      operators.operatorframework.io.bundle.package.v1="multicluster-engine" \
      operators.operatorframework.io.bundle.channels.v1="stable-2.9" \
      operators.operatorframework.io.bundle.channel.default.v1="stable-2.9" \
      com.redhat.openshift.versions="v4.16-v4.20"

LABEL com.redhat.component="multicluster-engine-operator-bundle-container" \
      name="multicluster-engine/mce-operator-bundle" \
      version="2.9.0-66" \
      summary="multicluster-engine-operator-bundle" \
      io.openshift.expose-services="" \
      io.openshift.tags="data,images" \
      io.k8s.display-name="multicluster-engine-operator-bundle" \
      maintainer="['acm-component-maintainers@redhat.com']" \
      description="multicluster-engine-operator-bundle" \
      konflux.additional-tags="v2.9.0-66,snapshot-release-mce-29-7ktxn"
