# IA Operating Systems

A hack.

## Notes

Export `GITHUB_DEBUG=1` for GitHub bindings debug spew.

`src/secrets` should contain an appropriately permissioned GitHub API token in a
file `token`.

## Updates

### 2016/17

<http://genode.org/documentation/articles/trustzone>
<http://genode.org/documentation/articles/arm_virtualization>

+ Add _translation between namespaces_ to core notions?
    + E.g., memory mapping, EPTs for VT-x, virtualisation more generally
+ Add _synchronous vs asynchronous_ to core notions?
    + E.g., DMA bus transactions affecting ability to trap illegal access
